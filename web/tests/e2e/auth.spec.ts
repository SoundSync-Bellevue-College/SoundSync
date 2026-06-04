import { expect, test, type APIRequestContext, type Page } from '@playwright/test'

const baseUser = {
  id: 'user-123',
  email: 'demo@soundsync.test',
  displayName: 'Demo Rider',
  notificationsEnabled: true,
  tempUnit: 'F',
  distanceUnit: 'mi',
}

let testUser = baseUser

async function mockApi(page: Page) {
  if (process.env.E2E_USE_REAL_API) return

  await page.route('**/api/v1/auth/login', async (route) => {
    const body = route.request().postDataJSON() as { email?: string; password?: string }

    if (body.email === 'bad-shape@soundsync.test') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ok: true }),
      })
      return
    }

    if (body.email !== baseUser.email || body.password !== 'password123') {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({ message: 'invalid email or password' }),
      })
      return
    }

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ token: 'test-jwt-token', user: baseUser }),
    })
  })

  await page.route('**/api/v1/users/me/notifications', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ notifications: [] }),
    })
  })

  await page.route('**/api/v1/users/me/favorites', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ favorites: [] }),
    })
  })
}

async function registerRealUser(request: APIRequestContext) {
  const email = `e2e_${Date.now()}_${Math.random().toString(16).slice(2)}@soundsync.test`
  const displayName = 'E2E Rider'

  const response = await request.post('/api/v1/auth/register', {
    data: {
      email,
      password: 'password123',
      displayName,
    },
  })

  expect(response.status()).toBe(201)
  testUser = { ...baseUser, email, displayName }
}

async function submitLogin(page: Page, email: string, password: string) {
  await page.goto('/login')
  await page.locator('input[type="email"]').fill(email)
  await page.locator('input[type="password"]').fill(password)
  await page.getByRole('button', { name: 'Sign In' }).click()
}

test.beforeEach(async ({ page, request }) => {
  testUser = baseUser
  if (process.env.E2E_USE_REAL_API) {
    await registerRealUser(request)
  }
  await mockApi(page)
})

test('redirects protected account page to login when signed out', async ({ page }) => {
  await page.goto('/account')

  await expect(page).toHaveURL(/\/login\?redirect=\/account$/)
  await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible()
})

test('logs in, stores JWT session, and sends Authorization on authenticated requests', async ({ page }) => {
  let favoritesAuthHeader = ''

  await page.route('**/api/v1/users/me/favorites', async (route) => {
    favoritesAuthHeader = route.request().headers().authorization ?? ''
    if (process.env.E2E_USE_REAL_API) {
      await route.continue()
      return
    }
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ favorites: [] }),
    })
  })

  await submitLogin(page, testUser.email, 'password123')

  await expect(page.getByText(testUser.displayName)).toBeVisible()
  await expect.poll(() => page.evaluate(() => localStorage.getItem('soundsync_token'))).toBeTruthy()

  await page.goto('/account')
  await expect(page.getByRole('heading', { name: testUser.displayName })).toBeVisible()
  await expect.poll(() => favoritesAuthHeader.startsWith('Bearer ')).toBe(true)
})

test('keeps the JWT-backed session after a page reload', async ({ page }) => {
  await submitLogin(page, testUser.email, 'password123')
  await expect(page.getByText(testUser.displayName)).toBeVisible()

  await page.reload()

  await expect(page.getByText(testUser.displayName)).toBeVisible()
  await expect(page.getByRole('link', { name: 'Account' })).toBeVisible()
})

test('shows backend error message for failed login', async ({ page }) => {
  await submitLogin(page, testUser.email, 'wrong-password')

  await expect(page.getByText(/invalid|password|credentials/i)).toBeVisible()
  await expect.poll(() => page.evaluate(() => localStorage.getItem('soundsync_token'))).toBeNull()
})

test('shows a clear error when login returns invalid JSON shape', async ({ page }) => {
  test.skip(!!process.env.E2E_USE_REAL_API, 'malformed response is covered with the mocked API')

  await submitLogin(page, 'bad-shape@soundsync.test', 'password123')

  await expect(page.getByText('Invalid login response from server')).toBeVisible()
  await expect.poll(() => page.evaluate(() => localStorage.getItem('soundsync_token'))).toBeNull()
})
