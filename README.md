# SoundSync

A real-time Seattle transit app that shows live bus positions, AI-powered reliability scores, and honest trip information — built as a Bellevue College CS 455 capstone project.

---

## What it does

SoundSync is a mobile transit companion for Seattle-area riders. It combines live vehicle data from OneBusAway, a machine-learning reliability service, and (soon) a RAG-backed natural-language assistant to give riders a genuinely honest picture of how the bus network is performing right now.

**Current feature set:**

- **Live map** — buses render as blue pills at their real positions, updated from the OneBusAway feed, with dedupe and freshness filtering
- **Buses near you** — sorted list of routes within 0.5 mi (auto-expands to 1 mi when fewer than two buses are nearby, and tells you it did)
- **AI Reliability banner** — network-wide on-time rate, refreshed every minute from the ML service
- **Route Detail** — tap any bus to see live status (count in service, occupancy, vehicle ID, trip ID, last-update timestamp) plus a per-route AI reliability score
- **Trip planning** — type a destination, get real transit directions and alternatives via Google Directions
- **Weather** — current conditions on the home screen via NOAA
- **Community reporting** — tap a bus to report cleanliness, crowding, or delays
- **Authentication** — Login and Signup screens using JWT tokens
- **Automated deployment** — CI/CD via GitHub Actions deploying to AWS on merges to `main`

**Coming next sprint:**

- RAG-powered Trip Assistant chat (built on top of Nolan's HuggingFace dataset of 400,000+ transit data points)
- Alternative Routes screen (once the stop-sequence endpoint is available)
- Real upcoming-stops schedule on Route Detail
- Expanded integration test coverage in CI

---

## Tech stack

| Layer | Stack |
|---|---|
| Mobile | Flutter + Riverpod + GoRouter + google_maps_flutter + dio |
| Backend | Go (chi router), REST under `/api/v1/` |
| Databases | PostgreSQL (real-time OBA arrival data) + MongoDB (users, reports, prefs) |
| ML service | Python reliability / prediction model, separate process |
| Data sources | OneBusAway GTFS-Realtime, Google Directions, NOAA Weather |
| LLM / RAG | HuggingFace-hosted dataset + open-source model (next sprint) |
| Deployment | Docker Compose (local), AWS via GitHub Actions (production) |

---

## Project structure

```
SoundSync/
├── api/                     # Go backend (Wayne)
│   └── internal/
│       ├── handlers/        # HTTP route handlers
│       ├── services/        # Including reliability_service.go (Nolan)
│       └── router/          # Chi route registration
├── mobile/                  # Flutter app (Abshira)
│   └── lib/
│       ├── screens/         # home_screen, route_detail_screen, login/signup, etc.
│       ├── widgets/         # reusable UI components
│       ├── services/        # api_client, routes_lookup, reliability_service
│       └── providers/       # Riverpod state
├── poller/                  # Python OneBusAway poller (Nolan)
├── .github/workflows/       # CI/CD pipelines (Tony)
├── docker-compose.yml       # local dev stack
└── .env                     # credentials (not committed)
```

---

## Running it locally

**Prereqs:** Docker Desktop, Go 1.22+, Flutter 3+, an Android emulator or physical device. Ask a teammate for the `.env` and `mobile/dart_defines.env` files.

```bash
# Terminal 1 — databases + poller
cd ~/SoundSync
docker compose up -d

# Terminal 2 — Go API
cd api
go run ./cmd/server

# Terminal 3 — Flutter app
cd mobile
flutter run --dart-define-from-file=dart_defines.env
```

The API serves at `http://localhost:8080`. The Android emulator rewrites this to `10.0.2.2:8080` automatically.

---

## Key endpoints the mobile app uses

| Endpoint | Purpose |
|---|---|
| `GET /api/v1/transit/vehicles` | Live bus positions (polled every 15s) |
| `GET /api/v1/reliability/summary` | Network-wide ML reliability scores |
| `GET /api/v1/weather` | Current weather conditions |
| `GET /api/v1/routes/plan` | Trip planning via Google Directions |
| `POST /api/v1/transit/vehicles/{id}/report/*` | User-submitted reports |
| `POST /api/v1/auth/login` | JWT authentication |
| `POST /api/v1/auth/signup` | Account creation |

Full endpoint list in the SRS (`SoundSync_SRS_v6.docx`).

---

## Deployment

Deployment to AWS is fully automated. On every merge to `main`:

1. GitHub Actions runs the automated test suite.
2. If tests pass, the pipeline builds the Go server + Flutter web bundle.
3. Artifacts are pushed to AWS.
4. Team members with IAM credentials can SSH into the deployed environment for debugging.

See `.github/workflows/` for the pipeline definitions.

---

## Team

- **Abshira Salat** — Flutter frontend, UX redesign, live-data integration, AI reliability UI, documentation
- **Wayne San** — Go backend, databases, initial API surface
- **Nolan** — ML reliability service, Python OBA poller, HuggingFace RAG dataset, LLM training
- **Tony** — AWS deployment pipeline, GitHub Actions CI/CD, IAM / SSH access, Login & Signup screens

Bellevue College CS 455 — Software Engineering Capstone, Spring 2026.

---

## Roadmap

See `SoundSync_SprintProgressReport.docx` for the detailed next-sprint action items. Headliners:

- Build the RAG-backed Trip Assistant chat on top of Nolan's dataset
- Ship the three missing backend endpoints (arrivals, route-stops sequence, server-side vehicle dedupe)
- Complete the Alternative Routes screen
- Expand CI with full integration tests

---

## License

All rights reserved. Bellevue College capstone project — not licensed for redistribution.
