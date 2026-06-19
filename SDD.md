# Software Design Document
## SoundSync — Real-Time Seattle Transit Application

**Version:** 1.0  
**Date:** 2026-06-18  
**Course:** CS 481 — Capstone 1, Bellevue College  
**Team:** Abshira Salat, Wayne San, Nolan, Tony  

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Architecture](#2-system-architecture)
3. [Backend API Design (Go)](#3-backend-api-design-go)
4. [Web Frontend Design (Vue 3)](#4-web-frontend-design-vue-3)
5. [Mobile Application Design (Flutter)](#5-mobile-application-design-flutter)
6. [Transit Poller Design (Python)](#6-transit-poller-design-python)
7. [Database Design](#7-database-design)
8. [Security Design](#8-security-design)
9. [Deployment and Infrastructure Design](#9-deployment-and-infrastructure-design)
10. [Inter-Component Communication](#10-inter-component-communication)

---

## 1. Introduction

### 1.1 Purpose

This Software Design Document (SDD) describes the architectural and detailed design of **SoundSync**. It translates the requirements defined in the SRS into concrete design decisions: component structure, module responsibilities, data models, API contracts, and interaction patterns.

### 1.2 Scope

This document covers all four major components of the SoundSync system:
- Go REST API backend
- Vue 3 TypeScript web frontend
- Flutter mobile application
- Python transit data poller

### 1.3 Design Goals

- **Separation of concerns:** Each layer (handler, service, repository) has a single responsibility.
- **Stateless API:** The backend holds no session state; all auth context is carried in JWT tokens.
- **Real-time freshness:** Client-side polling keeps data current without requiring WebSockets.
- **Portability:** Docker Compose enables identical dev and production environments.
- **Shared data contract:** Both web and mobile clients consume the same REST API, ensuring feature parity.

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Client Tier                               │
│                                                                  │
│   ┌─────────────────────┐      ┌─────────────────────────────┐  │
│   │  Web App (Vue 3)    │      │  Mobile App (Flutter)       │  │
│   │  Port 5173 (dev)    │      │  iOS / Android              │  │
│   │  AWS Amplify (prod) │      │  Google Maps Flutter SDK    │  │
│   └──────────┬──────────┘      └──────────────┬──────────────┘  │
└──────────────┼───────────────────────────────-┼─────────────────┘
               │ HTTPS REST (JSON)              │ HTTPS REST (JSON)
               ▼                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                       API Tier (Go)                              │
│                                                                  │
│   Chi Router  →  Middleware  →  Handlers  →  Services            │
│                  (JWT, CORS,               →  Repositories       │
│                   Logger)                                        │
│                  Port 8080                                       │
└───────┬──────────────┬──────────────┬──────────────┬────────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌───────────────┐
│PostgreSQL│  │   MongoDB    │  │ External │  │  External     │
│ Port 5432│  │  Port 27017  │  │  APIs    │  │  APIs         │
│(arrivals)│  │(users/reports│  │(OBA,     │  │(Anthropic,    │
│          │  │ /notifs/favs)│  │ GTFS-RT) │  │ Google Maps,  │
└──────────┘  └──────────────┘  └──────────┘  │ Weather)      │
        ▲                                      └───────────────┘
        │
┌───────┴──────────────┐
│  Python Transit       │
│  Poller              │
│  (60s interval)      │
│  OBA API → PostgreSQL│
└──────────────────────┘
```

### 2.2 Technology Stack

| Layer | Technology | Version | Role |
|-------|-----------|---------|------|
| Web frontend | Vue 3 + TypeScript | Vue 3.x | SPA browser client |
| Web build | Vite | 6.x | Bundler and dev server |
| Web state | Pinia | 2.x | Reactive state management |
| Web routing | Vue Router | 4.x | Client-side navigation |
| Web HTTP | Axios | 1.x | REST client with interceptors |
| Mobile | Flutter + Dart | SDK ≥3.3.0 | Cross-platform native app |
| Mobile state | Riverpod | 2.x | Reactive provider-based state |
| Mobile routing | GoRouter | 14.x | Declarative navigation |
| Mobile HTTP | Dio | 5.x | REST client with interceptors |
| Backend | Go | 1.22 | REST API server |
| Backend router | Chi | v5 | HTTP router and middleware |
| Backend auth | golang-jwt | v5 | JWT creation and validation |
| Backend crypto | golang.org/x/crypto | latest | bcrypt password hashing |
| Poller | Python | 3.12 | OBA polling service |
| Primary DB | PostgreSQL | 16 | Arrival history (time-series) |
| Secondary DB | MongoDB | 7.0 | Users, reports, notifications |
| Maps | Google Maps Platform | — | Maps, directions, geocoding |
| AI | Anthropic Claude | haiku-4-5-20251001 | Chatbot |
| Weather | NOAA / OpenWeatherMap | — | Weather data |
| Container | Docker / Docker Compose | — | Local dev orchestration |
| CI/CD | GitHub Actions | — | Build and deploy pipelines |
| Hosting | AWS Amplify | — | Frontend production hosting |

---

## 3. Backend API Design (Go)

### 3.1 Layered Architecture

The backend follows a strict three-layer architecture to isolate concerns:

```
HTTP Request
     │
     ▼
┌─────────────┐
│  Middleware  │  JWT validation, CORS headers, request ID, logging
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Handler   │  Parse request, call service, write JSON response
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Service   │  Business logic, external API calls, data transformation
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Repository  │  MongoDB CRUD — no business logic
└─────────────┘
```

**Rule:** Handlers never touch databases. Services never parse HTTP. Repositories never contain conditionals.

### 3.2 Package Structure

```
api/
├── cmd/
│   └── main.go                  # Entry point: load config → start server
└── internal/
    ├── config/
    │   └── config.go            # Reads env vars into Config struct
    ├── handlers/
    │   ├── auth.go              # Register, Login
    │   ├── chat.go              # Chat (Anthropic proxy)
    │   ├── notification.go      # GetNotifications, MarkRead, MarkAllRead
    │   ├── reliability.go       # GetSummary, GetStopReliability, GetPrediction
    │   ├── routes.go            # PlanRoute, GetRouteShape, GetRoute
    │   ├── serviceAlerts.go     # GetAlerts
    │   ├── team.go              # GetTeam
    │   ├── transit.go           # GetVehicles, GetNearbyStops, GetArrivals
    │   ├── user.go              # GetMe, UpdateSettings, DeleteMe, Favorites, Reports
    │   ├── vehicleReport.go     # CreateCleanliness/Crowding/Delay, GetMyReports, Delete
    │   └── weather.go           # GetWeather, GetHourlyForecast
    ├── middleware/
    │   ├── auth.go              # RequireAuth: JWT extract → set userID in context
    │   ├── cors.go              # CORS headers for allowed origins
    │   └── logger.go            # Structured request logging
    ├── models/
    │   ├── favorite.go          # FavoriteRoute struct
    │   ├── notification.go      # Notification struct
    │   ├── report.go            # Report struct
    │   ├── serviceAlert.go      # ServiceAlert struct
    │   ├── team.go              # TeamMember struct
    │   ├── user.go              # User struct
    │   ├── vehicle.go           # Vehicle struct
    │   └── vehicleReport.go     # Cleanliness/Crowding/DelayReport structs
    ├── repository/
    │   ├── favoriteRepo.go      # MongoDB CRUD for favorites
    │   ├── notificationRepo.go  # MongoDB CRUD for notifications
    │   ├── reportRepo.go        # MongoDB CRUD for reports
    │   ├── teamRepo.go          # MongoDB read for team
    │   ├── userRepo.go          # MongoDB CRUD for users
    │   └── vehicleReportRepo.go # MongoDB CRUD for vehicle reports
    ├── router/
    │   └── router.go            # Chi router: register all routes + middleware
    ├── server/
    │   └── server.go            # http.Server setup, graceful shutdown
    └── services/
        ├── authService.go       # Register, Login, GenerateToken, ValidateToken
        ├── reliability_service.go # Score computation, PostgreSQL queries
        ├── routeService.go      # Google Directions proxy
        ├── serviceAlertsService.go # GTFS-RT alert feed parsing
        ├── transitService.go    # GTFS-RT vehicle feed + OBA arrivals
        └── weatherService.go    # NOAA/OpenWeatherMap proxy
```

### 3.3 Configuration Design

All configuration is loaded from environment variables via `config.go` into a single `Config` struct passed to all services at startup. No global variables are used.

```go
type Config struct {
    Port              string
    Environment       string
    MongoURI          string
    MongoDB           string
    JWTSecret         string
    GoogleMapsKey     string
    GTFSVehicleURL    string
    GTFSTripUpdateURL string
    GTFSAlertURL      string
    KCMetroAlertURL   string
    OBABaseURL        string
    OBAKey            string
    PostgresDSN       string
    AnthropicKey      string
    WeatherAPIKey     string
}
```

### 3.4 Router Design

The Chi router is configured in `router/router.go` with two route groups:

**Public group** — no auth middleware:
```
GET  /api/v1/transit/vehicles
GET  /api/v1/transit/stops/nearby
GET  /api/v1/transit/stops/{stopId}/arrivals
GET  /api/v1/reliability/summary
GET  /api/v1/reliability/stop/{stopId}
GET  /api/v1/reliability/stop/{stopId}/route/{routeId}
GET  /api/v1/reliability/predict
GET  /api/v1/routes/plan
GET  /api/v1/routes/{id}/shape
GET  /api/v1/routes/{id}
GET  /api/v1/weather
GET  /api/v1/weather/hourly
GET  /api/v1/service-alerts
GET  /api/v1/crowdsource/{stopId}
GET  /api/v1/team
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/chat
```

**Protected group** — `RequireAuth` middleware applied:
```
GET    /api/v1/users/me
PUT    /api/v1/users/me/settings
DELETE /api/v1/users/me
GET    /api/v1/users/me/favorites
POST   /api/v1/users/me/favorites
DELETE /api/v1/users/me/favorites/{id}
POST   /api/v1/reports
GET    /api/v1/reports/mine
POST   /api/v1/vehicle-reports/cleanliness
POST   /api/v1/vehicle-reports/crowding
POST   /api/v1/vehicle-reports/delay
GET    /api/v1/vehicle-reports/mine
DELETE /api/v1/vehicle-reports/{id}
GET    /api/v1/notifications
PATCH  /api/v1/notifications/{id}/read
PATCH  /api/v1/notifications/read-all
```

CORS allows: `http://localhost:5173`, `http://localhost:4173`, `http://localhost:3003`, and the AWS Amplify production domain.

### 3.5 Service Designs

#### 3.5.1 Transit Service

Responsibilities: GTFS-RT vehicle feed parsing, OBA stop lookup, OBA arrival queries.

```
GetVehicles():
  1. HTTP GET GTFS-RT vehicle positions feed (protobuf)
  2. Decode FeedMessage → extract VehiclePosition entities
  3. Map each entity → Vehicle{vehicleId, routeId, tripId, lat, lng, bearing, speed,
     timestamp, occupancyStatus}
  4. Return []Vehicle

GetNearbyStops(lat, lng, radius):
  1. Query OBA /stops-for-location with lat, lng, radius
  2. Return []Stop{stopId, name, lat, lng, direction, routes[]}

GetArrivals(stopId):
  1. Query OBA /arrivals-and-departures-for-stop/{stopId}
  2. Map each arrival → Arrival{routeId, headsign, scheduledTime, predictedTime,
     delaySeconds, status}
  3. Return []Arrival
```

#### 3.5.2 Reliability Service

Responsibilities: Score computation from PostgreSQL arrival history.

```
GetStopReliability(stopId, routeId, timeBin, dayType):
  1. Query PostgreSQL:
     SELECT delay_seconds FROM arrivals
     WHERE stop_id=$1 AND route_id=$2
       AND recorded_at > NOW() - INTERVAL '90 days'
       AND time_bin=$3 AND day_type=$4
  2. Compute:
     on_time_rate   = count(|delay| ≤ 120) / total
     mean_delay     = avg(delay_seconds)
     stddev_delay   = stddev(delay_seconds)
     p90_delay      = 90th percentile of delay_seconds
     consistency    = 1 - (stddev / MAX_STDDEV), clamped [0,1]
     delay_score    = max(0, 1 - mean_delay / MAX_DELAY)
     score          = on_time_rate*50 + consistency*30 + delay_score*20
     confidence     = 1 - e^(-n/10)
  3. Return ReliabilityScore{score, onTimeRate, meanDelay, p90Delay, confidence, n}
```

#### 3.5.3 Auth Service

```
Register(email, password):
  1. Validate email format, password length ≥ 8
  2. Check email not already in users collection
  3. bcrypt.GenerateFromPassword(password, cost=12)
  4. Insert User{email, passwordHash, displayName=email prefix, ...}
  5. Return GenerateToken(userID)

Login(email, password):
  1. Find user by email
  2. bcrypt.CompareHashAndPassword(hash, password)
  3. Return GenerateToken(userID)

GenerateToken(userID):
  1. jwt.NewWithClaims(HS256, {sub: userID, exp: now+24h})
  2. Sign with JWTSecret from config
```

#### 3.5.4 Chat Service

```
Chat(message, conversationHistory):
  1. Build system prompt: Seattle transit assistant persona with
     awareness of routes, reliability scores, trip planning
  2. POST https://api.anthropic.com/v1/messages
     model: claude-haiku-4-5-20251001
     max_tokens: 1024
     system: <transit system prompt>
     messages: conversationHistory + {role:user, content:message}
  3. Return assistant message content
```

#### 3.5.5 Weather Service

```
GetWeather(lat, lng):
  1. GET OpenWeatherMap /weather?lat={lat}&lon={lng}&appid={key}&units=imperial
  2. Map response → WeatherData{temp, feelsLike, description, icon, humidity, windSpeed}
  3. Return WeatherData

GetHourlyForecast(lat, lng):
  1. GET OpenWeatherMap /forecast?lat={lat}&lon={lng}&appid={key}&units=imperial&cnt=8
  2. Map response → []HourForecast{time, temp, description, icon}
```

### 3.6 Middleware Design

#### JWT Auth Middleware (`RequireAuth`)

```
1. Extract "Authorization: Bearer <token>" header
2. If missing → 401 Unauthorized
3. jwt.ParseWithClaims(token, JWTSecret)
4. If invalid or expired → 401 Unauthorized
5. Set userID in request context via context.WithValue
6. Call next handler
```

Downstream handlers retrieve the user ID with:
```go
userID := r.Context().Value(middleware.UserIDKey).(string)
```

### 3.7 Error Response Convention

All API errors return a consistent JSON body:

```json
{
  "error": "human-readable message"
}
```

HTTP status codes used:
| Status | Meaning |
|--------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad request (malformed input) |
| 401 | Unauthorized (missing/invalid JWT) |
| 403 | Forbidden (valid JWT but insufficient permissions) |
| 404 | Resource not found |
| 409 | Conflict (e.g., email already registered) |
| 500 | Internal server error |
| 503 | Service unavailable (DB/external API down) |

---

## 4. Web Frontend Design (Vue 3)

### 4.1 Application Structure

```
web/src/
├── main.ts                    # Mount Vue app, register Pinia + Router
├── App.vue                    # Root: RouterView + global overlays (toast, alerts)
├── router/
│   └── index.ts               # Route definitions + navigation guards
├── stores/
│   ├── authStore.ts           # JWT, user profile, login/logout actions
│   ├── mapStore.ts            # Map center, zoom, selected stop/route
│   ├── notificationStore.ts   # Unread count, notification list, polling
│   ├── routeStore.ts          # Favorite routes cache
│   ├── serviceAlertStore.ts   # Active alerts, polling
│   ├── themeStore.ts          # Light/dark mode toggle + persistence
│   └── weatherStore.ts        # Current weather + hourly forecast cache
├── services/
│   ├── api.ts                 # Axios instance: baseURL, JWT interceptor, error handling
│   ├── authService.ts         # login(), register(), getMe(), updateSettings(), deleteAccount()
│   ├── mapsService.ts         # Google Maps JS API loader and map instance management
│   └── notificationService.ts # fetchNotifications(), markRead(), markAllRead()
├── components/
│   ├── common/
│   │   ├── AppHeader.vue      # Top nav bar: logo, links, notification badge, theme toggle
│   │   ├── ChatBot.vue        # Floating chatbot icon + expandable panel
│   │   ├── LoadingSpinner.vue # Reusable loading indicator
│   │   ├── NotificationToast.vue # Transient success/error messages
│   │   └── ServiceAlertDropdown.vue # Alert bell + dropdown list
│   ├── map/
│   │   ├── MapContainer.vue   # Google Map mount point, lifecycle management
│   │   ├── VehicleMarker.vue  # Bus icon marker with bearing rotation
│   │   ├── StopMarker.vue     # Stop pin marker
│   │   └── RoutePolyline.vue  # Encoded polyline rendering
│   ├── transit/
│   │   ├── ArrivalBoard.vue   # Stop arrivals list (auto-refreshes 30s)
│   │   ├── ReliabilityBadge.vue  # Color-coded score chip
│   │   ├── ReliabilityCard.vue   # Expanded score detail card
│   │   ├── RouteSearchPanel.vue  # Origin/destination inputs + plan button
│   │   ├── RouteSummaryCard.vue  # Trip planning result card
│   │   ├── RouteTrackPanel.vue   # Active route tracking sidebar
│   │   ├── StopAlertBanner.vue   # Per-stop alert message strip
│   │   └── VehicleReportModal.vue # Crowdsource report submission form
│   ├── user/
│   │   ├── LoginModal.vue     # Login form (email + password)
│   │   ├── RegisterModal.vue  # Registration form
│   │   └── FavoriteRouteCard.vue # Saved route entry with load/delete actions
│   └── weather/
│       └── WeatherWidget.vue  # Current temp + conditions + hourly strip
└── views/
    ├── HomeView.vue           # Primary page: map + sidebars
    ├── ScoreView.vue          # Reliability scores dashboard
    ├── AboutView.vue          # Project and team info
    ├── AccountView.vue        # User settings (protected)
    ├── LoginView.vue          # Full-page login (guest only)
    ├── RegisterView.vue       # Full-page registration (guest only)
    ├── PrivacyView.vue        # Privacy policy
    ├── MobileView.vue         # Mobile app promotion + QR code
    └── RouteDetailView.vue    # Route detail page (stub)
```

### 4.2 State Management Design (Pinia)

Each Pinia store is a self-contained module with state, getters, and actions.

#### authStore

```
state:
  token: string | null       (persisted to localStorage)
  user: UserProfile | null

actions:
  login(email, password)     → POST /auth/login → set token + user
  register(email, password)  → POST /auth/register → set token + user
  logout()                   → clear token + user
  fetchMe()                  → GET /users/me → set user
  updateSettings(settings)   → PUT /users/me/settings
  deleteAccount()            → DELETE /users/me → logout

getters:
  isAuthenticated            → token !== null
  displayName                → user?.displayName ?? 'Guest'
```

#### mapStore

```
state:
  center: {lat, lng}         (default: Bellevue, WA)
  zoom: number               (default: 13)
  selectedStop: Stop | null
  selectedRoute: Route | null
  vehicles: Vehicle[]
  planResult: TripPlan | null

actions:
  setCenter(lat, lng)
  selectStop(stop)
  selectRoute(route)
  fetchVehicles()            → GET /transit/vehicles → set vehicles (every 15s)
  planTrip(origin, dest)     → GET /routes/plan → set planResult
```

#### notificationStore

```
state:
  notifications: Notification[]
  unreadCount: number
  polling: boolean

actions:
  startPolling()             → fetchNotifications every 60s
  fetchNotifications()       → GET /notifications → set list + unreadCount
  markRead(id)               → PATCH /notifications/{id}/read
  markAllRead()              → PATCH /notifications/read-all
```

### 4.3 Routing Design

```typescript
const routes = [
  { path: '/',          component: HomeView },
  { path: '/route/:id', component: RouteDetailView },
  { path: '/score',     component: ScoreView },
  { path: '/about',     component: AboutView },
  { path: '/mobile',    component: MobileView },
  { path: '/privacy',   component: PrivacyView },
  { path: '/account',   component: AccountView,   meta: { requiresAuth: true } },
  { path: '/login',     component: LoginView,     meta: { guestOnly: true } },
  { path: '/register',  component: RegisterView,  meta: { guestOnly: true } },
]
```

Navigation guard logic:
- `requiresAuth: true` → redirect to `/login` if not authenticated
- `guestOnly: true` → redirect to `/` if already authenticated

### 4.4 API Client Design

`services/api.ts` exports a configured Axios instance:

```
baseURL: import.meta.env.VITE_API_URL  (default: http://localhost:8080/api/v1)

Request interceptor:
  - If authStore.token exists → add "Authorization: Bearer {token}" header

Response interceptor:
  - 401 response → authStore.logout() + redirect to /login
  - Network error → throw with user-friendly message
```

### 4.5 Polling Strategy

| Data | Interval | Component/Store |
|------|----------|----------------|
| Vehicle positions | 15 seconds | mapStore.fetchVehicles() |
| Stop arrivals | 30 seconds | ArrivalBoard.vue internal timer |
| Notifications | 60 seconds | notificationStore.startPolling() |
| Service alerts | Page load | serviceAlertStore (no repeat poll) |
| Weather | On viewport change | weatherStore (cached, no repeat) |

All polling uses `setInterval` started in `onMounted` and cleared in `onUnmounted` to prevent memory leaks.

### 4.6 ChatBot Component Design

```
State:
  isOpen: boolean
  messages: [{role, content}]
  inputText: string
  loading: boolean

Flow:
  1. User types message → inputText
  2. Submit → POST /chat {message, history}
  3. Append user + assistant messages to messages[]
  4. If assistant response contains structured route data:
     → Emit 'route-autofill' event with origin/destination
     → Parent (HomeView) receives event → calls mapStore.planTrip()
     → Auto-trigger directions rendering

Positioning (mobile web):
  - Icon: fixed, top-left of map, z-index above controls
  - Panel: opens downward to avoid obscuring map bottom controls
```

---

## 5. Mobile Application Design (Flutter)

### 5.1 Application Structure

```
mobile/lib/
├── main.dart                  # ProviderScope, GoRouter, theme, app startup
├── providers/
│   ├── auth_provider.dart     # Authentication state (login, logout, token)
│   ├── location_provider.dart # Device GPS position stream
│   ├── vehicles_provider.dart # Live vehicle list (15s refresh)
│   ├── reliability_provider.dart # Reliability score data
│   └── route_provider.dart    # Trip planning state
├── screens/
│   ├── main_shell.dart        # Bottom navigation scaffold (Home/Chat/Scores/Account)
│   ├── home_screen.dart       # Full-screen map + overlaid panels
│   ├── route_detail_screen.dart # Route live status and arrivals
│   ├── chat_screen.dart       # Chatbot conversation UI
│   ├── scores_screen.dart     # Reliability scores list/detail
│   ├── account_screen.dart    # User profile and settings
│   ├── about_screen.dart      # Project and team info
│   └── auth/
│       ├── login_screen.dart  # Email/password login form
│       └── register_screen.dart # Account creation form
├── services/
│   ├── api_client.dart        # Dio instance: baseURL, JWT interceptor, secure storage
│   ├── chat_service.dart      # POST /chat with conversation history
│   ├── geocoding_service.dart # Address ↔ coordinates via Google Geocoding API
│   ├── reliability_service.dart # GET /reliability endpoints
│   ├── route_planning_service.dart # GET /routes/plan
│   └── routes_lookup.dart     # Load static route metadata from CSV asset
└── widgets/
    ├── arrival_card.dart      # Single arrival row with delay badge
    ├── reliability_gauge.dart # Animated score gauge widget
    ├── route_summary_tile.dart # Trip plan result list tile
    ├── vehicle_info_sheet.dart # Bottom sheet for tapped vehicle detail
    └── weather_chip.dart      # Compact weather display chip
```

### 5.2 State Management Design (Riverpod)

All state is managed via Riverpod providers. Code generation (`riverpod_generator` + `build_runner`) is used for `@riverpod` annotated providers.

```
authProvider (StateNotifierProvider):
  state: AuthState{token, user, status}
  methods: login(), register(), logout(), restoreToken()
  storage: flutter_secure_storage (token persisted between launches)

locationProvider (StreamProvider):
  stream: Geolocator.getPositionStream(
    locationSettings: LocationSettings(accuracy: high, distanceFilter: 10m)
  )

vehiclesProvider (FutureProvider, auto-refresh):
  future: apiClient.get('/transit/vehicles')
  refresh: ref.keepAlive() + periodic invalidation every 15s

reliabilityProvider (FutureProvider.family):
  family key: (stopId, routeId, timeBin)
  future: reliabilityService.getStopReliability(...)
```

### 5.3 Navigation Design (GoRouter)

```dart
final router = GoRouter(routes: [
  ShellRoute(
    builder: (ctx, state, child) => MainShell(child: child),
    routes: [
      GoRoute(path: '/',        builder: HomeScreen),
      GoRoute(path: '/chat',    builder: ChatScreen),
      GoRoute(path: '/scores',  builder: ScoresScreen),
      GoRoute(path: '/account', builder: AccountScreen,
              redirect: (ctx, state) => !isAuth ? '/login' : null),
    ],
  ),
  GoRoute(path: '/route/:id', builder: RouteDetailScreen),
  GoRoute(path: '/login',     builder: LoginScreen),
  GoRoute(path: '/register',  builder: RegisterScreen),
]);
```

App startup flow in `main.dart`:
1. Show splash screen
2. `authProvider.restoreToken()` — reads from secure storage
3. If token valid → navigate to `/`; else → navigate to `/login`

### 5.4 HTTP Client Design (Dio)

`services/api_client.dart` configures a Dio instance:

```
baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080/api/v1')
  (10.0.2.2 is the Android emulator's localhost alias)

Interceptors:
  Request:  read token from flutter_secure_storage → add Authorization header
  Response: 401 → clear stored token → navigate to /login
  Error:    wrap DioException in user-readable AppException
```

### 5.5 Theme Design

The mobile app uses a fixed dark theme:

```dart
ThemeData(
  colorScheme: ColorScheme.dark(
    primary:    Color(0xFF7FDBFF),  // Cyan accent
    surface:    Color(0xFF122340),  // Navy panel background
    background: Color(0xFF0D1B2A),  // Deep navy page background
    onPrimary:  Colors.black,
    onSurface:  Colors.white,
  ),
  useMaterial3: true,
)
```

### 5.6 Home Screen Layout

```
┌────────────────────────────────┐
│  GoogleMap (full screen)       │
│  ┌────────────────────────┐   │
│  │  AI Reliability Banner  │   │ ← overlaid at top
│  └────────────────────────┘   │
│                                │
│  [vehicle markers]             │
│  [stop markers]                │
│                                │
│  ┌──────────────────┐         │
│  │  Weather Widget   │         │ ← overlaid bottom-left
│  └──────────────────┘         │
│                 ┌───────────┐  │
│                 │  FAB: Plan │  │ ← floating action button
│                 └───────────┘  │
└────────────────────────────────┘
│  Bottom Navigation Bar         │
│  Home │ Chat │ Scores │Account │
└────────────────────────────────┘
```

Gesture support: horizontal swipe on the main shell switches between bottom nav tabs.

---

## 6. Transit Poller Design (Python)

### 6.1 Overview

The transit poller is a standalone Python service running in a Docker container. It queries the OneBusAway API for arrival predictions, computes delays relative to schedule, and writes records to PostgreSQL every 60 seconds.

### 6.2 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   poller.py                         │
│                                                     │
│  while True:                                        │
│    for stop_id in MONITORED_STOPS:                  │
│      response = GET OBA /arrivals/{stop_id}         │
│      for arrival in response.data:                  │
│        delay = (predicted_ms - scheduled_ms) / 1000 │
│        INSERT INTO arrivals (...)                   │
│    sleep(60)                                        │
└─────────────────────────────────────────────────────┘
```

### 6.3 Monitored Stops

Configured in `stops.py`:

| Stop ID | Location |
|---------|----------|
| `1_67652` | Bellevue area stop |
| `1_68007` | Bellevue area stop |
| `1_72984` | Bellevue area stop |
| `1_72983` | Bellevue area stop |

### 6.4 Data Written per Arrival

```sql
INSERT INTO arrivals (
  stop_id, route_id, trip_id, headsign,
  scheduled_arrival_ms, predicted_arrival_ms,
  delay_seconds, recorded_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
```

`delay_seconds = (predicted_arrival_ms - scheduled_arrival_ms) / 1000.0`

### 6.5 Error Handling

- OBA API timeout or non-200 response: log error, skip this stop, continue loop
- PostgreSQL connection error: log error, attempt reconnect on next cycle
- Individual arrival parse error: log warning, skip that arrival record

---

## 7. Database Design

### 7.1 PostgreSQL — Arrival History

Used exclusively by the transit poller (writes) and reliability service (reads).

#### Table: `arrivals`

```sql
CREATE TABLE arrivals (
  id                    SERIAL PRIMARY KEY,
  stop_id               VARCHAR(50)  NOT NULL,
  route_id              VARCHAR(50)  NOT NULL,
  trip_id               VARCHAR(100),
  headsign              VARCHAR(200),
  scheduled_arrival_ms  BIGINT       NOT NULL,
  predicted_arrival_ms  BIGINT       NOT NULL,
  delay_seconds         FLOAT        NOT NULL,
  recorded_at           TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_arrivals_stop_route_time
  ON arrivals (stop_id, route_id, recorded_at DESC);
```

**Rationale for PostgreSQL:** The reliability service runs aggregate queries (AVG, STDDEV, COUNT, percentile) over large time ranges. PostgreSQL's query planner handles these efficiently with the composite index, which MongoDB cannot match for time-series analytical queries.

**Retention:** The reliability service filters to `recorded_at > NOW() - INTERVAL '90 days'`. No explicit purge job is implemented; old rows accumulate but are ignored by queries.

### 7.2 MongoDB — Application Data

Used by all user-facing features.

#### Collection: `users`

```json
{
  "_id": ObjectId,
  "email": "string (unique, indexed)",
  "passwordHash": "string (bcrypt)",
  "displayName": "string",
  "notificationsEnabled": true,
  "tempUnit": "F | C",
  "distanceUnit": "miles | km",
  "deleted": false,
  "createdAt": ISODate,
  "updatedAt": ISODate
}
```

Index: `{ email: 1 }` unique.

#### Collection: `favorite_routes`

```json
{
  "_id": ObjectId,
  "userID": ObjectId,
  "label": "string",
  "origin": {
    "name": "string",
    "lat": 47.6,
    "lng": -122.3
  },
  "destination": {
    "name": "string",
    "lat": 47.6,
    "lng": -122.3
  },
  "transitRouteIds": ["40", "255"],
  "createdAt": ISODate
}
```

Index: `{ userID: 1 }`.

#### Collection: `vehicle_reports`

```json
{
  "_id": ObjectId,
  "userID": ObjectId,
  "routeId": "string",
  "vehicleId": "string",
  "type": "cleanliness | crowding | delay",
  "level": 3,
  "createdAt": ISODate
}
```

Index: `{ userID: 1 }`, `{ routeId: 1, type: 1 }` (for crowdsource summary queries).

#### Collection: `reports`

```json
{
  "_id": ObjectId,
  "userID": ObjectId,
  "routeId": "string",
  "vehicleId": "string",
  "type": "string",
  "severity": "string",
  "description": "string",
  "location": "string",
  "createdAt": ISODate
}
```

#### Collection: `notifications`

```json
{
  "_id": ObjectId,
  "userID": ObjectId,
  "routeID": "string",
  "reportType": "string",
  "message": "string",
  "read": false,
  "createdAt": ISODate
}
```

Index: `{ userID: 1, read: 1 }` (for unread count queries).

#### Collection: `team`

```json
{
  "_id": ObjectId,
  "name": "string",
  "role": "string",
  "bio": "string",
  "photoUrl": "string"
}
```

Static — seeded at database initialization, read-only at runtime.

### 7.3 Data Initialization

`database/` contains initialization scripts that:
1. Create the PostgreSQL `arrivals` table with index
2. Seed the MongoDB `team` collection with team member profiles

These run automatically when Docker Compose starts the database containers.

---

## 8. Security Design

### 8.1 Authentication Flow

```
Client                          API Server                      MongoDB
  │                                │                               │
  │── POST /auth/login ──────────► │                               │
  │   {email, password}            │── FindUser(email) ──────────► │
  │                                │◄─ {passwordHash} ─────────────│
  │                                │   bcrypt.Compare(pw, hash)    │
  │                                │   GenerateJWT(userID, 24h)    │
  │◄─ {token, user} ──────────────│                               │
  │                                │                               │
  │── GET /users/me ─────────────► │                               │
  │   Authorization: Bearer <tok>  │   ParseJWT → extract userID   │
  │                                │── FindUser(userID) ─────────► │
  │◄─ {user profile} ─────────────│◄─ {user} ─────────────────────│
```

### 8.2 JWT Design

- Algorithm: HS256 (HMAC-SHA256)
- Claims: `sub` (userID), `exp` (now + 24h), `iat` (issued at)
- Secret: 256-bit random string from environment variable `JWT_SECRET`
- Transport: `Authorization: Bearer <token>` header only (never in URL or cookie)
- Client storage — web: `localStorage`; mobile: `flutter_secure_storage` (Keychain/Keystore)

### 8.3 Password Security

- bcrypt cost factor: 12
- Minimum length: 8 characters (enforced in auth handler)
- No maximum length restriction (bcrypt handles long inputs safely)
- Password reset: not implemented in v1.0 (out of scope)

### 8.4 CORS Policy

Allowed origins configured in `middleware/cors.go`:
- `http://localhost:5173` (Vite dev)
- `http://localhost:4173` (Vite preview)
- `http://localhost:3003` (alt dev port)
- `https://*.amplifyapp.com` (production)

Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS  
Headers: Content-Type, Authorization  
Credentials: false (JWT in header, not cookie)

### 8.5 Secrets Management

All secrets stored in `.env` (never committed):
```
JWT_SECRET=
GOOGLE_MAPS_KEY=
OBA_KEY=
ANTHROPIC_KEY=
WEATHER_API_KEY=
MONGO_URI=
POSTGRES_DSN=
```

`.gitignore` explicitly excludes `.env`.

---

## 9. Deployment and Infrastructure Design

### 9.1 Local Development (Docker Compose)

```yaml
services:
  postgres:
    image: postgres:16
    ports: ["5432:5432"]
    volumes: [postgres_data:/var/lib/postgresql/data]
    environment: [POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD]

  mongo:
    image: mongo:7.0
    ports: ["27017:27017"]
    volumes: [mongo_data:/data/db]

  mongo-express:
    image: mongo-express
    ports: ["8081:8081"]     # Web-based MongoDB GUI

  transit-poller:
    build: ./transit-poller
    depends_on: [postgres]
    environment: [POSTGRES_*, OBA_BASE_URL, OBA_KEY]
```

The Go API and Vue frontend run outside Docker in local dev for faster rebuild cycles.

### 9.2 CI/CD Pipeline (GitHub Actions)

Workflows trigger on push to `main` and on pull requests:

```
.github/workflows/
├── build-api.yml     # go build ./... && go vet ./...
├── build-web.yml     # npm ci && npm run build
└── deploy.yml        # On merge to main: deploy to AWS Amplify
```

Branch protection on `main`: PRs must pass CI before merging.

### 9.3 Production Deployment (AWS Amplify)

- **Web frontend:** Deployed to AWS Amplify from `web/` directory. Amplify auto-detects Vite and runs `npm run build`. Environment variables (`VITE_API_URL`, `VITE_GOOGLE_MAPS_KEY`) set in Amplify console.
- **Backend API:** Runs on a cloud VM or container service (configuration managed by Tony via IAM/SSH).
- **Databases:** PostgreSQL and MongoDB run as managed services or on the same VM as the API.
- **Transit Poller:** Runs as a Docker container on the same host as the API.

---

## 10. Inter-Component Communication

### 10.1 Web Component Communication Patterns

| Pattern | Used For |
|---------|---------|
| Pinia store (shared state) | Vehicle data, auth state, map center, notifications |
| Vue props | Parent-to-child data (e.g., vehicle data → VehicleMarker) |
| Vue emits | Child-to-parent events (e.g., ChatBot emits 'route-autofill' → HomeView) |
| Provide/inject | Not used (Pinia covers global state needs) |

### 10.2 Map ↔ Sidebar Communication

```
HomeView
  ├── MapContainer (emits: stopClick, vehicleClick)
  ├── ArrivalBoard (receives: selectedStop from mapStore)
  ├── RouteSearchPanel (emits: planRoute → mapStore.planTrip)
  ├── RoutePolyline (receives: planResult from mapStore)
  └── ChatBot (emits: route-autofill → HomeView → mapStore.planTrip)
```

### 10.3 Mobile Widget Communication Patterns

| Pattern | Used For |
|---------|---------|
| Riverpod providers | All shared state (auth, location, vehicles, reliability) |
| ConsumerWidget | Any widget reading provider state |
| Callbacks | Parent → child (e.g., onVehicleTap) |
| GoRouter navigation | Screen transitions with parameters |

### 10.4 Notification Fan-Out Flow

```
User A submits report on Route 40
        │
        ▼
POST /vehicle-reports/crowding  {routeId: "40", ...}
        │
        ▼
vehicleReportHandler → vehicleReportRepo.Create()
        │
        ▼
FanOutNotifications(routeId: "40"):
  1. Query favorite_routes WHERE "40" IN transitRouteIds
  2. For each owner (User B, User C ...):
     notificationRepo.Insert({userID, routeID: "40", message: "..."})
        │
        ▼
User B polls GET /notifications → sees unread notification
```

---

*End of Software Design Document*
