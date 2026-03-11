# SoundSyncAI — Setup Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker Desktop | latest | https://docs.docker.com/get-docker/ |
| Node.js | 20+ | https://nodejs.org |
| Go | 1.22+ | https://go.dev/dl/ |
| Flutter | 3.x | https://docs.flutter.dev/get-started/install |

## API Keys Required

| Service | Purpose | Get Key |
|---------|---------|---------|
| Google Maps JS API | Map rendering, geocoding, directions | Google Cloud Console |
| OpenWeatherMap | Weather widget | https://openweathermap.org/api |

Sound Transit GTFS-RT feeds are public (no key required).

## Step 1 — Clone & Configure

```bash
git clone <repo-url>
cd SoundSyncWS
cp .env.example .env
```

Edit `.env` and fill in your API keys.

## Step 2 — Start Database

```bash
docker compose up -d
```

Verify:
- MongoDB: `mongodb://localhost:27017`
- mongo-express GUI: http://localhost:8081 (admin / admin)

## Step 3 — Start Backend API

```bash
cd api
go mod download
go run main.go
```

API available at http://localhost:8080. Health check: `GET /health`

## Step 4 — Start Frontend

```bash
cd web
npm install
npm run dev
```

App available at http://localhost:5173.

## Step 5 — Mobile (optional)

```bash
cd mobile
flutter pub get
flutter run
```

## Google Maps Setup

1. Enable these APIs in Google Cloud Console:
   - Maps JavaScript API
   - Geocoding API
   - Directions API
2. Add your key to `.env` as both `GOOGLE_MAPS_API_KEY` and `VITE_GOOGLE_MAPS_API_KEY`
3. Restrict the key by referrer (`localhost:5173`, your production domain)

## Verifying Everything Works

```bash
# Database GUI
open http://localhost:8081

# API health
curl http://localhost:8080/health

# Vehicle positions
curl http://localhost:8080/api/v1/transit/vehicles

# Frontend
open http://localhost:5173
```
