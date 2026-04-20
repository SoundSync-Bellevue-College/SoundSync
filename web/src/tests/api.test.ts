import { describe, it, expect, beforeEach, vi } from 'vitest'
import MockAdapter from 'axios-mock-adapter'
import api from '../services/api'

// mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => (store[key] = value),
    clear: () => (store = {}),
  }
})()

vi.stubGlobal('localStorage', localStorageMock)

describe('api.ts', () => {
  let mock: MockAdapter

  beforeEach(() => {
    localStorage.clear()
    mock = new MockAdapter(api)
  })

  it('adds Authorization header when token exists', async () => {
    localStorage.setItem('soundsync_token', 'test-token')

    mock.onGet('/test').reply((config) => {
      expect(config.headers?.Authorization).toBe('Bearer test-token')
      return [200, {}]
    })

    await api.get('/test')
  })

  it('does not add Authorization header if no token', async () => {
    mock.onGet('/test').reply((config) => {
      expect(config.headers?.Authorization).toBeUndefined()
      return [200, {}]
    })

    await api.get('/test')
  })

  it('formats backend error message', async () => {
    mock.onGet('/error').reply(400, { message: 'Backend error' })

    await expect(api.get('/error')).rejects.toThrow('Backend error')
  })

  it('falls back to default error message', async () => {
    mock.onGet('/error').networkError()

    await expect(api.get('/error')).rejects.toThrow()
  })
})