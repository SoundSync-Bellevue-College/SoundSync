# Final Spring Progress Report
## SoundSync — Real-Time Seattle Transit Application

**Course:** CS 481 — Capstone 1, Bellevue College  
**Term:** Spring 2026  
**Date:** June 18, 2026  
**Team Members:** Abshira Salat, Wayne San, Nolan, Tony  

---

## 1. Executive Summary

SoundSync is a full-stack real-time transit application built for Seattle-area riders. Over the course of Spring 2026, the team completed the transition from a working prototype into a fully deployed, production-quality system. This report documents the features delivered, the technical architecture implemented, the production deployment pipeline established, and the lessons learned across the term.

The application is live and accessible through a web browser and as a native mobile app (Flutter) for Android and iOS. The backend API, transit data poller, and two databases run continuously in production. All code changes flow through an automated CI/CD pipeline that runs tests and deploys to AWS on every merge to the `main` branch.

---

## 2. Project Overview

SoundSync gives Seattle-area transit riders honest, AI-powered information about how the bus network is performing right now. Rather than showing only schedule data, it layers machine-learning reliability scores, real-time crowdsourced vehicle reports, and a natural-language AI transit assistant on top of live OneBusAway and GTFS-Realtime feeds.

### 2.1 Completed Feature Set

By the end of Spring 2026, the following features were fully implemented and deployed:

| Feature | Status |
|---------|--------|
| Live interactive map with real-time bus markers | Complete |
| Buses near you (0.5 mi radius, auto-expands to 1 mi) | Complete |
| Stop arrival boards with predicted times | Complete |
| AI-powered reliability scores (0–100, time-of-day segmented) | Complete |
| Reliability score dashboard (Scores page) | Complete |
| Trip planning via Google Directions | Complete |
| AI transit chatbot (Anthropic Claude) | Complete |
| Chatbot route auto-fill + auto-trigger directions | Complete |
| Crowdsourced vehicle reports (cleanliness, crowding, delay) | Complete |
| Service alerts (Sound Transit + King County Metro) | Complete |
| Real-time weather widget | Complete |
| User registration and login (JWT auth) | Complete |
| Account settings (temp unit, distance unit, notifications) | Complete |
| Saved favorite routes | Complete |
| In-app notifications for favorited route reports | Complete |
| Light and dark theme support (web) | Complete |
| Flutter mobile app (iOS + Android) with full feature parity | Complete |
| Mobile app promotion page with QR code | Complete |
| Team / About page (dynamic from API) | Complete |
| Production deployment with CI/CD | Complete |
| Software documentation (SRS, SDD, STD) | Complete |

---

## 3. System Architecture

SoundSync is a monorepo with four independently deployable components connected through a shared REST API.

```
┌──────────────────────────────────────────────────────────────┐
│                      Client Tier                             │
│   Web App (Vue 3 + TypeScript)    Mobile App (Flutter)       │
│   Hosted on AWS Amplify           iOS / Android              │
└─────────────────────┬────────────────────┬───────────────────┘
                      │ HTTPS REST          │ HTTPS REST
                      ▼                    ▼
┌──────────────────────────────────────────────────────────────┐
│              Go REST API  —  Port 8080                       │
│   Chi router · JWT middleware · 6 service modules           │
└──────┬─────────────┬──────────────┬──────────────┬──────────┘
       │             │              │              │
  PostgreSQL      MongoDB       OBA API /       Anthropic /
  (arrivals)   (users, etc.)   GTFS-RT feeds   Google / NOAA
       ▲
┌──────┴──────────────┐
│  Python Transit      │
│  Poller (60s cycle)  │
└─────────────────────┘
```

### 3.1 Technology Choices

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Web frontend | Vue 3 + TypeScript + Vite | Fast build times, strong typing, reactive component model |
| State management | Pinia | Lightweight, TypeScript-native, replaces Vuex cleanly |
| Mobile | Flutter | Single codebase for Android and iOS; strong Google Maps plugin |
| Mobile state | Riverpod | Type-safe, testable, replaces Provider pattern |
| Backend | Go + Chi router | High performance, low memory footprint, excellent concurrency |
| Transit arrivals DB | PostgreSQL 16 | Efficient aggregate queries (AVG, STDDEV, percentile) for reliability scoring |
| User data DB | MongoDB 7.0 | Flexible document model for evolving user profile schema |
| Transit data | OneBusAway + GTFS-Realtime | Official Sound Transit and King County Metro data |
| AI chatbot | Anthropic Claude (haiku-4-5) | Fast response time, cost-effective for high-volume chat |
| Maps | Google Maps Platform | Directions, geocoding, and native Flutter/JS SDK |
| Weather | OpenWeatherMap | Reliable hourly forecast API with free tier |

---

## 4. Sprint Accomplishments by Team Member

### 4.1 Wayne San — Go Backend and Databases

Wayne designed and built the entire REST API backend in Go, including:

- **Chi router** with middleware chain: JWT auth, CORS, request logging, and panic recovery
- **Six service modules:** transit (GTFS-RT + OBA), reliability (PostgreSQL analytics), auth (bcrypt + JWT), chat (Anthropic proxy), weather (OpenWeatherMap proxy), and service alerts (GTFS-RT alert feeds)
- **MongoDB repositories** for users, favorite routes, vehicle reports, general reports, and notifications
- **Notification fan-out system:** when a user submits a crowdsource report, all users who have favorited that route receive an in-app notification automatically
- **Account management endpoints:** registration, login, profile update, soft-delete
- **Two-database architecture:** PostgreSQL for time-series arrival data (queried by the reliability service with aggregate SQL), MongoDB for all user-facing document data

Backend API exposes 30+ endpoints across public and authenticated route groups.

### 4.2 Abshira Salat — Flutter Mobile Application and UX

Abshira built the full Flutter mobile application and contributed to the web frontend UX:

- **Full-screen home map** with overlaid vehicle markers, stop markers, weather chip, reliability banner, and route planning FAB
- **Riverpod state providers** for auth, GPS location, live vehicles, reliability scores, and trip planning
- **GoRouter navigation** with bottom navigation shell (Home / Chat / Scores / Account)
- **Gesture support:** swipe between tabs, bottom sheet for vehicle detail
- **Route Detail screen** with live stop arrivals and per-route reliability card
- **Scores screen** with animated reliability gauge widgets
- **Auth screens** (login, register) with JWT token stored in `flutter_secure_storage`
- **Dark theme** (primary `#7FDBFF`, surface `#122340`, background `#0D1B2A`)
- **Mobile UX improvements** in the final sprint: gesture navigation, route detail floating action button, map polish, and dynamic page titles

### 4.3 Nolan — AI/ML Reliability Service and Transit Poller

Nolan built the data intelligence layer:

- **Python transit poller:** Queries the OneBusAway API every 60 seconds for 4 Bellevue-area stops, computes `delay_seconds = (predicted - scheduled) / 1000`, and inserts records into PostgreSQL
- **Reliability scoring formula** (implemented in `api/internal/services/reliability_service.go`):
  - On-time rate (±2 min tolerance): 50% weight
  - Consistency score (inverse standard deviation): 30% weight
  - Average delay score: 20% weight
  - Confidence score: `1 - e^(-n/10)` based on sample count
  - Time-of-day segmentation: morning, midday, afternoon, evening, night
  - 90-day rolling lookback window
- **AI chatbot integration:** Integrated Anthropic Claude API with a transit-specific system prompt; the chatbot can interpret natural-language trip requests and auto-populate the route planning fields
- **Chatbot auto-trigger:** After chatbot fills in a route, directions are automatically triggered without requiring a second user action

### 4.4 Tony — CI/CD Pipeline and AWS Deployment

Tony designed and implemented the full production deployment pipeline:

- **GitHub Actions workflow** (`.github/workflows/tests.yml`): Runs on every push and pull request
  - `backend` job: Spins up a MongoDB 7.0 service container, sets up Go 1.22, runs `go test ./...` against the real database
  - `frontend` job: Sets up Node 20, installs dependencies with `npm ci`, installs Playwright Chromium, runs TypeScript build check (`npm run build`), then runs E2E tests (`npm run test:e2e`)
- **AWS deployment:** Frontend deployed to AWS Amplify; backend and databases on AWS infrastructure
- **IAM and SSH access** management for team members
- **Branch protection on `main`:** All PRs must pass the full CI test suite before merging

---

## 5. Production Deployment

### 5.1 Deployment Architecture

The production deployment consists of three independently running tiers:

```
Internet
    │
    ▼
┌─────────────────────────────────────────────┐
│            AWS Amplify (Frontend)            │
│  Vue 3 SPA — auto-deployed on main merge    │
│  HTTPS with CDN + SSL certificate           │
│  Env vars: VITE_API_URL, VITE_GOOGLE_KEY    │
└─────────────────────┬───────────────────────┘
                      │ HTTPS API calls
                      ▼
┌─────────────────────────────────────────────┐
│       Backend Server (AWS EC2 / VM)          │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Go API  (port 8080)                │   │
│  │  go run ./cmd/server                │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Docker Compose (data tier)          │  │
│  │  ├── soundsync_postgres  :5432       │  │
│  │  ├── soundsync_mongo     :27017      │  │
│  │  ├── soundsync_poller    (internal)  │  │
│  │  └── soundsync_mongo_express :8081   │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 5.2 CI/CD Pipeline Detail

Every code change follows this automated path from commit to production:

```
Developer pushes branch / opens PR
            │
            ▼
  GitHub Actions triggered
            │
     ┌──────┴──────┐
     │             │
  backend       frontend
   job            job
     │             │
  Spin up       npm ci
  MongoDB        │
  container      │
     │          npm run build
  go test        (TypeScript typecheck)
  ./...          │
     │          npx playwright install
     │          npm run test:e2e
     │             │
     └──────┬──────┘
            │
    Both jobs pass?
            │
     ┌──────┴──────┐
    YES            NO
     │              │
  PR can merge    PR blocked;
     │             fix required
     ▼
  Merge to main
     │
     ▼
  AWS Amplify detects push to main
  → Pulls latest code
  → Runs: npm ci && npm run build
  → Deploys built assets to CDN
  → New version live (typically < 3 minutes)
```

### 5.3 GitHub Actions Workflow Configuration

The CI pipeline is defined in `.github/workflows/tests.yml`:

**Backend Job:**
- Runs on `ubuntu-latest`
- Spins up a `mongo:7.0` service container with health checks (mongosh ping, 10s interval, 5 retries) to ensure the database is ready before tests run
- Uses `actions/setup-go@v5` with Go version pinned from `api/go.mod` and dependency caching from `api/go.sum`
- Runs `go test ./...` from the `api/` directory with `MONGO_URI` pointed at the service container

**Frontend Job:**
- Runs on `ubuntu-latest`
- Uses `actions/setup-node@v4` with Node 20 and npm cache enabled from `web/package-lock.json`
- Runs `npm ci` (clean install, respects lockfile exactly — no version drift)
- Installs Playwright Chromium with system dependencies (`--with-deps`)
- Runs `npm run build` to catch TypeScript type errors and bundling failures
- Runs `npm run test:e2e` for Playwright end-to-end tests against the built app

### 5.4 Local Development Environment (Docker Compose)

The `docker-compose.yml` at the repository root defines the complete local data tier:

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| `soundsync_postgres` | postgres:16 | 5432 | Transit arrival history (time-series data for reliability scoring) |
| `soundsync_mongo` | mongo:7.0 | 27017 | Users, favorites, reports, notifications |
| `soundsync_poller` | Built from `./transit-poller` | — (internal) | Polls OBA API every 60s, writes to PostgreSQL |
| `soundsync_mongo_express` | mongo-express:1.0 | 8081 | Web GUI for MongoDB inspection during development |

All containers connect over a private Docker network (`soundsync_network`) so they communicate by service name rather than localhost. Data is persisted in named volumes (`soundsync_postgres_data`, `soundsync_mongo_data`) so the database survives container restarts.

The poller container `depends_on: postgres`, ensuring PostgreSQL is healthy before the poller starts its first OBA query cycle.

Credentials for all services are injected from the `.env` file using Docker Compose variable substitution (e.g., `${PG_PASSWORD:-postgres}` with a fallback default for first-time setup).

### 5.5 Environment Variable Management

Secrets and environment-specific configuration are managed through `.env` files, which are explicitly excluded from source control via `.gitignore`. Required variables include:

| Variable | Used By | Description |
|----------|---------|-------------|
| `JWT_SECRET` | Go API | Signs and verifies all JWT tokens |
| `MONGO_URI` | Go API | MongoDB connection string |
| `GOOGLE_MAPS_KEY` | Go API, Web, Mobile | Maps, Directions, Geocoding APIs |
| `OBA_API_KEY` | Python poller | OneBusAway API authentication |
| `ANTHROPIC_KEY` | Go API | Claude chatbot API |
| `WEATHER_API_KEY` | Go API | OpenWeatherMap API |
| `PG_USER / PG_PASSWORD / PG_DBNAME` | PostgreSQL, poller, Go API | Database credentials |
| `VITE_API_URL` | Vue web app (build-time) | Backend API base URL |
| `VITE_GOOGLE_MAPS_KEY` | Vue web app (build-time) | Google Maps JS API key |

In production (AWS Amplify), environment variables are set in the Amplify console so they are never stored in the repository.

### 5.6 Database Initialization

The `database/mongo-init/` directory contains initialization scripts that are mounted as Docker entrypoint scripts. These run automatically on first container start and seed:
- The `team` collection with the four team member profiles (used by the About page)
- Any required indexes on MongoDB collections

The PostgreSQL `arrivals` table and its performance index are created by a SQL init script that also runs on first container start.

---

## 6. Key Technical Challenges and Resolutions

### 6.1 Chatbot Mobile Layout Conflict

**Challenge:** When the AI chatbot was integrated into the mobile web view, the floating chat icon overlapped the map controls and the panel opened in a direction that obscured the map area on small screens.

**Resolution:** The chatbot icon was repositioned to the top-left of the map area with a higher z-index, and the panel was configured to open downward rather than upward, avoiding overlap with the bottom navigation bar. This required two PR iterations (PR #60, PR #62) to fully resolve across different mobile viewport sizes.

### 6.2 Chatbot Auto-Trigger Directions

**Challenge:** After the chatbot parsed a trip request and filled in origin/destination fields, users had to manually click "Plan Trip" — an extra step that broke the conversational flow.

**Resolution:** The chatbot's route-autofill event was wired to automatically call the trip planning service, so directions render immediately after the chatbot fills in the fields. This was implemented by having the `ChatBot` Vue component emit a `route-autofill` event that `HomeView` listens for and passes directly to `mapStore.planTrip()`.

### 6.3 Two-Database Architecture Complexity

**Challenge:** Using both PostgreSQL and MongoDB added operational complexity — two connection pools, two health checks, and two initialization scripts to manage.

**Resolution:** This design decision was justified by the workload difference: PostgreSQL handles time-series aggregate queries (AVG, STDDEV, COUNT over 90 days of arrivals) that MongoDB cannot execute as efficiently, while MongoDB's flexible document model fits the evolving user profile and report schemas. Docker Compose dependency ordering and health checks ensure the databases are ready before dependent services start.

### 6.4 GTFS-RT Feed Parsing

**Challenge:** The GTFS-Realtime feeds from Sound Transit and King County Metro use protobuf encoding, not JSON, and the feed structures differ slightly between agencies.

**Resolution:** The `transitService.go` and `serviceAlertsService.go` each fetch and decode the feeds using Go's protobuf library. The service alert handler merges alerts from both agencies into a single response array, applying a consistent `ServiceAlert` model regardless of the source feed format.

### 6.5 GitHub Actions MongoDB Service Container

**Challenge:** The backend test suite requires a running MongoDB instance, but connecting to an external database from CI is insecure and adds a network dependency.

**Resolution:** The GitHub Actions workflow uses a MongoDB 7.0 service container (`services:` block) that runs in a sidecar alongside the test runner. A health check (`mongosh --eval 'db.adminCommand("ping")'`) ensures the database accepts connections before `go test` runs. This keeps tests self-contained with no external dependencies.

---

## 7. Metrics

| Metric | Value |
|--------|-------|
| Total pull requests merged | 62+ |
| GitHub Actions runs | Automated on every push and PR |
| API endpoints delivered | 30+ |
| Flutter screens | 9 screens + reusable widgets |
| Vue components | 20+ components across 9 views |
| PostgreSQL records (arrivals) | Growing continuously (60s polling cycle × 4 stops) |
| External APIs integrated | 6 (OBA, Sound Transit GTFS-RT, King County GTFS-RT, Google Maps, Anthropic, OpenWeatherMap) |
| Documentation files | SRS, SDD, STD, README, DEMO.md, docs/api.md, docs/setup.md |

---

## 8. What Was Planned vs. What Was Delivered

The README from earlier in the term listed the following as "coming next sprint." All items were completed:

| Planned Item | Outcome |
|-------------|---------|
| RAG-powered Trip Assistant chat | Delivered — Anthropic Claude chatbot with transit system prompt, auto-fill, and auto-trigger |
| Alternative Routes screen | Delivered as part of the trip planning panel |
| Real upcoming-stops schedule on Route Detail | Delivered via OBA arrivals endpoint |
| Expanded integration test coverage in CI | Delivered — Playwright E2E tests run in GitHub Actions on every merge |

Additional features delivered beyond the original plan:
- Service alerts from both Sound Transit and King County Metro
- Full notification fan-out system for favorited route reports
- Light/dark theme toggle for the web app
- Mobile app promotion page with QR code
- Dynamic About/Team page driven from the API
- Full software documentation (SRS, SDD, STD)

---

## 9. Lessons Learned

**Monorepo structure pays off.** Keeping the Go API, Vue web app, Flutter mobile app, and Python poller in a single repository simplified cross-component changes. A single PR could update the API contract and both clients simultaneously, reducing integration issues.

**Docker Compose is essential for team consistency.** Using Docker Compose for the database layer eliminated "works on my machine" issues. Every team member ran identical PostgreSQL and MongoDB versions with the same initialization scripts.

**CI from day one reduces integration pain.** Having GitHub Actions run tests on every push caught regressions early and made merging to `main` low-risk. The MongoDB service container pattern in particular made backend tests genuinely reliable without mocking.

**Two databases for two workloads is justified.** The decision to use PostgreSQL for arrival data and MongoDB for user data was initially debated as over-engineering. In practice, PostgreSQL's aggregate query performance for the reliability scoring queries (STDDEV, percentile over 90 days of records) was significantly better than what could be achieved with MongoDB's aggregation pipeline.

**Chatbot UX requires iteration.** The AI chatbot feature required multiple refinement passes. The core API integration was straightforward, but making the mobile layout work correctly and ensuring the auto-trigger behavior felt natural took two full PR cycles. UX testing on actual mobile devices (not just emulators) revealed issues that were invisible in desktop testing.

---

## 10. Conclusion

The SoundSync team delivered a complete, deployed, production-quality transit application over the Spring 2026 term. The application combines real-time GTFS data, machine-learning reliability scoring, AI-powered trip assistance, and community-sourced vehicle reporting into a unified experience for Seattle-area riders.

The production system is accessible at its AWS Amplify URL and continues to collect arrival data every 60 seconds via the transit poller. All code changes are protected by a two-job CI pipeline (backend tests against a live MongoDB container, frontend typecheck and Playwright E2E tests) that must pass before any branch can merge to `main`.

The three software documentation artifacts — SRS, SDD, and STD — provide a complete record of the system requirements, design decisions, and test plan for future maintainers or students who may build on this codebase.

---

*Submitted by the SoundSync Team — Bellevue College CS 481 Capstone 1, Spring 2026*
