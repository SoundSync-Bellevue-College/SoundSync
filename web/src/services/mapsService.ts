import { Loader } from '@googlemaps/js-api-loader'

let loader: Loader | null = null
let loaded = false

export function getMapsLoader(): Loader {
  if (!loader) {
    loader = new Loader({
      apiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
      version: 'weekly',
    })
  }
  return loader
}

export async function loadGoogleMaps(): Promise<typeof google.maps> {
  if (loaded) return google.maps
  await Promise.all([
    getMapsLoader().importLibrary('maps'),
    getMapsLoader().importLibrary('places'),
    getMapsLoader().importLibrary('geometry'),
  ])
  loaded = true
  return google.maps
}

export async function geocodeAddress(address: string): Promise<google.maps.LatLngLiteral | null> {
  await loadGoogleMaps()
  return new Promise((resolve) => {
    const geocoder = new google.maps.Geocoder()
    geocoder.geocode({ address }, (results, status) => {
      if (status === 'OK' && results?.[0]) {
        const loc = results[0].geometry.location
        resolve({ lat: loc.lat(), lng: loc.lng() })
      } else {
        resolve(null)
      }
    })
  })
}

export async function decodePolyline(encoded: string): Promise<google.maps.LatLngLiteral[]> {
  await loadGoogleMaps()
  return google.maps.geometry.encoding
    .decodePath(encoded)
    .map((p) => ({ lat: p.lat(), lng: p.lng() }))
}
