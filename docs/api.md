# SoundSyncAI — REST API Reference

Base URL: `http://localhost:8080/api/v1`

All responses are `application/json`. Authenticated endpoints require `Authorization: Bearer <jwt>`.

---

## Public Endpoints

### Transit

#### `GET /transit/vehicles`
Returns real-time vehicle positions from Sound Transit GTFS-RT.

**Response**
```json
{
  "vehicles": [
    {
      "vehicleId": "string",
      "routeId": "string",
      "tripId": "string",
      "lat": 47.6062,
      "lng": -122.3321,
      "bearing": 270,
      "speed": 12.5,
      "timestamp": "2024-01-01T12:00:00Z",
      "occupancyStatus": "MANY_SEATS_AVAILABLE"
    }
  ]
}
```

#### `GET /transit/stops?lat=&lng=&radius=`
Returns nearby stops from GTFS static data.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `lat` | float | yes | Latitude |
| `lng` | float | yes | Longitude |
| `radius` | int | no | Meters (default: 500) |

#### `GET /transit/arrivals?stopId=`
Returns upcoming arrivals at a stop from GTFS-RT TripUpdates.

| Param | Type | Required |
|-------|------|----------|
| `stopId` | string | yes |

---

### Routes

#### `GET /routes/plan?origin=&dest=`
Proxies Google Maps Directions API for transit routing.

| Param | Type | Example |
|-------|------|---------|
| `origin` | string | `47.6062,-122.3321` |
| `dest` | string | `47.6503,-122.3499` |

#### `GET /routes/:routeId`
Returns static GTFS route data.

---

### Weather

#### `GET /weather?lat=&lng=`
Proxies OpenWeatherMap current weather.

---

### Auth

#### `POST /auth/register`
```json
{ "email": "user@example.com", "password": "secret", "displayName": "Jane" }
```

#### `POST /auth/login`
```json
{ "email": "user@example.com", "password": "secret" }
```
**Response**: `{ "token": "<jwt>", "user": { ... } }`

---

## Authenticated Endpoints

### Users

#### `GET /users/me`
Returns current user profile.

### Favorites

#### `GET /users/me/favorites`
Returns user's saved routes.

#### `POST /users/me/favorites`
```json
{
  "label": "Home → Work",
  "origin": { "name": "Capitol Hill", "lat": 47.6253, "lng": -122.3222 },
  "destination": { "name": "Bellevue TC", "lat": 47.6150, "lng": -122.1973 },
  "transitRouteIds": ["550", "554"]
}
```

#### `DELETE /users/me/favorites/:id`
Deletes a saved favorite.

### Reports

#### `POST /reports`
```json
{
  "routeId": "550",
  "vehicleId": "9301",
  "type": "crowding",
  "severity": "high",
  "description": "Standing room only",
  "location": { "lat": 47.6062, "lng": -122.3321 }
}
```

#### `GET /reports?routeId=`
Returns recent condition reports for a route (last 30 days).
