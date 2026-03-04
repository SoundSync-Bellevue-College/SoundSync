# SoundSync Backend (Go)

REST API service in Go with JWT authentication and MongoDB persistence.

This API is now aligned with your Mongo schema design:
- `users` collection with `handle`, `password/password_hash`, `createdDate`, `notifications`
- notification settings stored inside `users.notifications`
- `delay_reports` collection for rider delay submissions

## Requirements
- Go 1.22+
- MongoDB running at:
  - `mongodb://admin:adminpassword@localhost:27017/?directConnection=true`

## Environment Variables
- `APP_ADDR` (default: `:8080`)
- `MONGO_URI` (default: `mongodb://admin:adminpassword@localhost:27017/?directConnection=true`)
- `MONGO_DB` (default: `soundsync`)
- `JWT_SECRET` (default: `replace-this-secret`)
- `JWT_TTL` (default: `24h`)

## Local Setup
1. Copy `.env.example` to `.env`
2. Set a strong `JWT_SECRET` in `.env`
3. Start the API with `go run ./cmd/server`

## Endpoints
- `GET /health`
- `POST /api/v1/auth/signup`
  - body: `{ "handle": "wayne_dev", "password": "secret123" }`
- `POST /api/v1/auth/login`
  - body: `{ "handle": "wayne_dev", "password": "secret123" }`
- `POST /api/v1/auth/logout` (requires bearer token)

Notification preferences (stored in `users.notifications`):
- `GET /api/v1/notifications`
- `PUT /api/v1/notifications/preferences`
  - body: `{ "enabled": true }`
- `POST /api/v1/notifications/subscriptions`
  - body: `{ "routeId": "100001" }`
- `DELETE /api/v1/notifications/subscriptions/{routeId}`

Delay reports:
- `POST /api/v1/delay-reports`
  - body: `{ "routeId":"100001", "stopId":"100", "directionId":0, "vehicle_id":"veh_100001_050", "report_time":"2026-02-10T21:00:00Z", "delay_minutes":4 }`
- `GET /api/v1/delay-reports`
  - optional query: `routeId`, `stopId`, `directionId`, `limit`

Crowding reports:
- `POST /api/v1/crowding-reports`
  - body: `{ "routeId":"100001", "stopId":"100", "directionId":0, "vehicle_id":"veh_100001_051", "report_time":"2026-02-10T21:05:00Z", "crowding_level":3 }`
- `GET /api/v1/crowding-reports`
  - optional query: `routeId`, `stopId`, `directionId`, `limit`

Cleanliness reports:
- `POST /api/v1/cleanliness-reports`
  - body: `{ "routeId":"100001", "stopId":"100", "directionId":0, "vehicle_id":"veh_100001_052", "report_time":"2026-02-10T21:10:00Z", "cleanliness_level":4 }`
- `GET /api/v1/cleanliness-reports`
  - optional query: `routeId`, `stopId`, `directionId`, `limit`

## Postman API Test Cases
Files:
- `postman/SoundSync-API-Tests.postman_collection.json`
- `postman/SoundSync-Local.postman_environment.json`

Run steps:
1. Start API server: `go run ./cmd/server`
2. Import both files into Postman.
3. Select environment: `SoundSync Local`.
4. Run the collection `SoundSync Backend API Tests` in order.

