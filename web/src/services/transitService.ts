import api from './api'
import type { VehiclePosition, Stop, Arrival } from '@/types/transit'

// Placeholder vehicles used before the Go backend is running
const MOCK_VEHICLES: VehiclePosition[] = [
  {
    vehicleId: '9301',
    routeId: '550',
    tripId: 'trip-001',
    lat: 47.6062,
    lng: -122.3321,
    bearing: 90,
    speed: 14.5,
    timestamp: new Date().toISOString(),
    occupancyStatus: 'MANY_SEATS_AVAILABLE',
  },
  {
    vehicleId: '9302',
    routeId: '41',
    tripId: 'trip-002',
    lat: 47.6253,
    lng: -122.3222,
    bearing: 180,
    speed: 10.2,
    timestamp: new Date().toISOString(),
    occupancyStatus: 'FEW_SEATS_AVAILABLE',
  },
  {
    vehicleId: '9303',
    routeId: '1 Line',
    tripId: 'trip-003',
    lat: 47.5989,
    lng: -122.3261,
    bearing: 0,
    speed: 22.0,
    timestamp: new Date().toISOString(),
    occupancyStatus: 'STANDING_ROOM_ONLY',
  },
]

export const transitService = {
  async getVehicles(): Promise<VehiclePosition[]> {
    try {
      const { data } = await api.get<{ vehicles: VehiclePosition[] }>('/transit/vehicles')
      const vehicles = data.vehicles ?? []
      if (vehicles.length === 0) {
        // Backend returned an empty feed (URL stale or off-hours) — use mock
        console.warn('Backend returned 0 vehicles — using mock vehicle data')
        return MOCK_VEHICLES
      }
      return vehicles
    } catch {
      // Fall back to mock data while backend is not yet running
      console.warn('Using mock vehicle data (backend offline)')
      return MOCK_VEHICLES
    }
  },

  async getNearbyStops(lat: number, lng: number, radius = 500): Promise<Stop[]> {
    const { data } = await api.get<{ stops: Stop[] }>('/transit/stops', {
      params: { lat, lng, radius },
    })
    return data.stops
  },

  async getArrivals(stopId: string): Promise<Arrival[]> {
    const { data } = await api.get<{ arrivals: Arrival[] }>('/transit/arrivals', {
      params: { stopId },
    })
    return data.arrivals
  },
}
