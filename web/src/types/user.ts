export interface User {
  id: string
  email: string
  displayName: string
  notificationsEnabled: boolean
  tempUnit: 'F' | 'C'
  distanceUnit: 'mi' | 'km'
  createdAt: string
}

export interface Notification {
  id: string
  userId: string
  routeId: string
  reportType: string
  message: string
  read: boolean
  createdAt: string
}

export interface LoginPayload {
  email: string
  password: string
}

export interface RegisterPayload {
  email: string
  password: string
  displayName: string
}

export interface AuthResponse {
  token: string
  user: User
}

export interface FavoriteRoute {
  _id: string
  userId: string
  label: string
  origin: PlaceRef
  destination: PlaceRef
  transitRouteIds: string[]
  createdAt: string
}

export interface PlaceRef {
  name: string
  lat: number
  lng: number
}

export interface CreateFavoritePayload {
  label: string
  origin: PlaceRef
  destination: PlaceRef
  transitRouteIds: string[]
}

export interface VehicleReport {
  id: string
  type: 'cleanliness' | 'crowding' | 'delay'
  vehicleId: string
  routeId: string
  level: number
  createdAt: string
}
