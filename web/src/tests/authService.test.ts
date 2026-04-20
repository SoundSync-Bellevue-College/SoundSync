import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import MockAdapter from 'axios-mock-adapter'
import api from '../services/api'
import { authService } from '../services/authService'

describe('authService', () => {
  let mock: MockAdapter

  beforeEach(() => {
    mock = new MockAdapter(api)
  })

  afterEach(() => {
    mock.restore()
  })

  it('login calls /auth/login and returns data', async () => {
    const payload = {
      email: 'test@test.com',
      password: '123456',
    }

    const response = {
      token: 'abc',
      user: { id: '1' },
    }

    mock.onPost('/auth/login', payload).reply(200, response)

    const result = await authService.login(payload)

    expect(result).toEqual(response)
  })

  it('register calls /auth/register and returns data', async () => {
    const payload = {
      email: 'test@test.com',
      password: '123456',
      displayName: 'Test User',
    }

    const response = {
      token: 'abc',
      user: { id: '1' },
    }

    mock.onPost('/auth/register', payload).reply(200, response)

    const result = await authService.register(payload)

    expect(result).toEqual(response)
  })

  it('getMe calls /users/me and returns user', async () => {
    const user = {
      id: '1',
      email: 'test@test.com',
    }

    mock.onGet('/users/me').reply(200, user)

    const result = await authService.getMe()

    expect(result).toEqual(user)
  })

  it('updateSettings calls /users/me/settings', async () => {
    const settings = {
      notificationsEnabled: true,
    }

    mock.onPatch('/users/me/settings', settings).reply(200)

    await authService.updateSettings(settings)

    expect(mock.history.patch.length).toBe(1)
    expect(JSON.parse(mock.history.patch[0].data)).toEqual(settings)
  })

  it('deleteAccount calls /users/me', async () => {
    mock.onDelete('/users/me').reply(200)

    await authService.deleteAccount()

    expect(mock.history.delete.length).toBe(1)
  })
})