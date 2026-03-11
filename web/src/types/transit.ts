export interface VehiclePosition {
  vehicleId: string
  routeId: string
  tripId: string
  lat: number
  lng: number
  bearing: number
  speed: number
  timestamp: string
  occupancyStatus?: string
}

export interface Stop {
  stopId: string
  name: string
  lat: number
  lng: number
  routes: string[]
}

export interface Arrival {
  tripId: string
  routeId: string
  routeShortName: string
  headsign: string
  scheduledArrival: string
  estimatedArrival?: string
  delaySeconds?: number
  status: 'ON_TIME' | 'DELAYED' | 'EARLY' | 'UNKNOWN'
}

export interface Route {
  routeId: string
  shortName: string
  longName: string
  type: number // GTFS route_type
  color?: string
  textColor?: string
}

export interface RoutePlan {
  origin: LatLng
  destination: LatLng
  legs: RouteLeg[]
  totalDurationMinutes: number
  totalDistanceMeters: number
  departureTime: string
  arrivalTime: string
}

export interface RouteLeg {
  mode: 'WALK' | 'BUS' | 'RAIL' | 'FERRY'
  routeId?: string
  routeShortName?: string
  headsign?: string
  from: { name: string } & LatLng
  to: { name: string } & LatLng
  durationMinutes: number
  distanceMeters?: number
  polyline?: string
}

export interface LatLng {
  lat: number
  lng: number
}

export interface Report {
  _id: string
  userId: string
  routeId: string
  vehicleId?: string
  type: 'delay' | 'cleanliness' | 'crowding' | 'other'
  severity: 'low' | 'medium' | 'high'
  description?: string
  location?: LatLng
  createdAt: string
}

export interface CreateReportPayload {
  routeId: string
  vehicleId?: string
  type: Report['type']
  severity: Report['severity']
  description?: string
  location?: LatLng
}
