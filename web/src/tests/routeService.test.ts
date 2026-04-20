import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import MockAdapter from 'axios-mock-adapter'
import api from '../services/api'
import { routeService } from '../services/routeService'

describe('routeService', () => {
  let mock: MockAdapter

  beforeEach(() => {
    mock = new MockAdapter(api)
  })

  afterEach(() => {
    mock.restore()
  })

  it('planRoute calls /routes/plan with correct params', async () => {
    const origin = { lat: 47.6, lng: -122.3 }
    const destination = { lat: 47.7, lng: -122.4 }

    const response = { routes: [] }

    mock.onGet('/routes/plan').reply((config) => {
      expect(config.params).toEqual({
        origin: '47.6,-122.3',
        dest: '47.7,-122.4',
      })
      return [200, response]
    })

    const result = await routeService.planRoute(origin, destination)

    expect(result).toEqual(response)
  })

  it('getRoute calls /routes/:id', async () => {
    const route = { id: '123' }

    mock.onGet('/routes/123').reply(200, route)

    const result = await routeService.getRoute('123')

    expect(result).toEqual(route)
  })

  it('getFavorites returns favorites array', async () => {
    const response = {
      favorites: [{ id: '1' }],
    }

    mock.onGet('/users/me/favorites').reply(200, response)

    const result = await routeService.getFavorites()

    expect(result).toEqual(response.favorites)
  })

  it('createFavorite posts payload and returns data', async () => {
    const payload = {
      label: 'Home → School',
      origin: {
        name: 'Home',
        lat: 47.6,
        lng: -122.3,
      },
      destination: {
        name: 'School',
        lat: 47.7,
        lng: -122.4,
      },
      transitRouteIds: ['route-1'],
    }

    const response = {
      id: '1',
      ...payload,
    }

    mock.onPost('/users/me/favorites', payload).reply(200, response)

    const result = await routeService.createFavorite(payload)

    expect(result).toEqual(response)
  })

  it('deleteFavorite calls correct endpoint', async () => {
    mock.onDelete('/users/me/favorites/1').reply(200)

    await routeService.deleteFavorite('1')

    expect(mock.history.delete.length).toBe(1)
  })
})