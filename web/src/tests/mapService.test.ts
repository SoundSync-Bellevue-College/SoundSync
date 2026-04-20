import { describe, it, expect, beforeEach, vi } from 'vitest'
import { geocodeAddress, decodePolyline, getMapsLoader } from '../services/mapsService'

const importLibraryMock = vi.fn()

vi.mock('@googlemaps/js-api-loader', () => ({
  Loader: vi.fn(() => ({
    importLibrary: importLibraryMock,
  })),
}))

describe('mapService', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    importLibraryMock.mockResolvedValue({})

    vi.stubGlobal('google', {
      maps: {
        Geocoder: vi.fn(() => ({
          geocode: vi.fn((_, callback) => {
            callback(
              [
                {
                  geometry: {
                    location: {
                      lat: () => 47.6,
                      lng: () => -122.3,
                    },
                  },
                },
              ],
              'OK'
            )
          }),
        })),
        geometry: {
          encoding: {
            decodePath: vi.fn(() => [
              { lat: () => 47.6, lng: () => -122.3 },
            ]),
          },
        },
      },
    })
  })

  it('returns the same loader instance', () => {
    expect(getMapsLoader()).toBe(getMapsLoader())
  })

  it('geocodeAddress returns coordinates', async () => {
    const result = await geocodeAddress('Seattle')

    expect(result).toEqual({ lat: 47.6, lng: -122.3 })
  })

  it('decodePolyline returns decoded points', async () => {
    const result = await decodePolyline('abc123')

    expect(result).toEqual([{ lat: 47.6, lng: -122.3 }])
  })
})