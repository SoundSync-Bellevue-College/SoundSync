import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import MockAdapter from 'axios-mock-adapter'
import api from '../services/api'
import { transitService } from '../services/transitService'

describe('transitService', () => {
  let mock: MockAdapter

  beforeEach(() => {
    mock = new MockAdapter(api)
    vi.spyOn(console, 'warn').mockImplementation(() => {})
  })

  afterEach(() => {
    mock.restore()
    vi.restoreAllMocks()
  })

  it('getVehicles returns backend vehicles when available', async () => {
    const response = {
      vehicles: [
        {
          vehicleId: '9301',
          routeId: '550',
          tripId: 'trip-001',
          lat: 47.6062,
          lng: -122.3321,
          bearing: 90,
          speed: 14.5,
          timestamp: '2025-01-01T00:00:00Z',
          occupancyStatus: 'MANY_SEATS_AVAILABLE',
        },
      ],
    }

    mock.onGet('/transit/vehicles').reply(200, response)

    const result = await transitService.getVehicles()

    expect(result).toEqual(response.vehicles)
  })

  it('getVehicles falls back to mock vehicles when backend returns empty array', async () => {
    mock.onGet('/transit/vehicles').reply(200, { vehicles: [] })

    const result = await transitService.getVehicles()

    expect(result.length).toBeGreaterThan(0)
    expect(console.warn).toHaveBeenCalled()
  })

  it('getVehicles falls back to mock vehicles when request fails', async () => {
    mock.onGet('/transit/vehicles').networkError()

    const result = await transitService.getVehicles()

    expect(result.length).toBeGreaterThan(0)
    expect(console.warn).toHaveBeenCalled()
  })

  it('getNearbyStops calls /transit/stops with correct params', async () => {
    const response = {
      stops: [
        {
          stopId: 'stop-1',
          name: 'Main St',
          lat: 47.6,
          lng: -122.3,
        },
      ],
    }

    mock.onGet('/transit/stops').reply((config) => {
      expect(config.params).toEqual({
        lat: 47.6,
        lng: -122.3,
        radius: 500,
      })
      return [200, response]
    })

    const result = await transitService.getNearbyStops(47.6, -122.3)

    expect(result).toEqual(response.stops)
  })

  it('getArrivals calls /transit/arrivals with stopId', async () => {
    const response = {
      arrivals: [
        {
          routeId: '550',
          arrivalTime: '2025-01-01T12:00:00Z',
        },
      ],
    }

    mock.onGet('/transit/arrivals').reply((config) => {
      expect(config.params).toEqual({
        stopId: 'stop-1',
      })
      return [200, response]
    })

    const result = await transitService.getArrivals('stop-1')

    expect(result).toEqual(response.arrivals)
  })
})