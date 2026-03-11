# SoundSyncAI

A public transit tracking and navigation app for Sound Transit (Seattle buses/rail). Think Google Maps, focused on real-time Sound Transit data.

## Stack

| Layer | Technology |
|-------|------------|
| Frontend | Vue 3 + Vite + TypeScript + Pinia |
| Backend | Go + chi router |
| Database | MongoDB 7.0 |
| Maps | Google Maps JS API |
| Transit Data | Sound Transit GTFS-RT |
| Weather | OpenWeatherMap API |
| Mobile | Flutter + Riverpod |

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- Go 1.22+
- Flutter 3.x

### 1. Environment
```bash
cp .env.example .env
# Edit .env with your API keys
```

### 2. Database
```bash
docker compose up -d
# MongoDB on :27017, mongo-express on :8081
```

### 3. Backend
```bash
cd api
go mod download
go run main.go
# API on :8080
```

### 4. Frontend
```bash
cd web
npm install
npm run dev
# App on :5173
```

### 5. Mobile (optional)
```bash
cd mobile
flutter pub get
flutter run
```

## Project Structure

```
SoundSyncWS/
├── web/        # Vue 3 + Vite frontend
├── api/        # Go REST API
├── mobile/     # Flutter app
├── database/   # MongoDB init scripts & schemas
└── docs/       # API reference & setup guide
```

## API Reference

See [docs/api.md](docs/api.md) for full endpoint documentation.

## Setup Guide

See [docs/setup.md](docs/setup.md) for detailed environment setup instructions.
