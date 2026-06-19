# Software Test Document
## SoundSync — Real-Time Seattle Transit Application

**Version:** 1.0  
**Date:** 2026-06-18  
**Course:** CS 481 — Capstone 1, Bellevue College  
**Team:** Abshira Salat, Wayne San, Nolan, Tony  

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Test Strategy](#2-test-strategy)
3. [Test Environment](#3-test-environment)
4. [Unit Tests](#4-unit-tests)
5. [Integration Tests](#5-integration-tests)
6. [End-to-End Tests](#6-end-to-end-tests)
7. [Performance Tests](#7-performance-tests)
8. [Security Tests](#8-security-tests)
9. [Mobile-Specific Tests](#9-mobile-specific-tests)
10. [Test Results and Acceptance Criteria](#10-test-results-and-acceptance-criteria)

---

## 1. Introduction

### 1.1 Purpose

This Software Test Document (STD) defines the test plan, test cases, and acceptance criteria for **SoundSync**. It traces test coverage back to the functional requirements defined in the SRS and the component designs defined in the SDD.

### 1.2 Scope

Testing covers all four system components:
- Go REST API backend
- Vue 3 TypeScript web frontend
- Flutter mobile application
- Python transit data poller

### 1.3 Testing Objectives

- Verify each functional requirement (FR) from the SRS is implemented correctly
- Verify non-functional requirements (performance, security, usability) are met
- Detect regressions introduced by new changes via automated CI checks
- Validate the system end-to-end from a rider's perspective before demo

### 1.4 Test Item Identification

| Component | Test Framework | Test Type |
|-----------|---------------|-----------|
| Go API — unit | Go `testing` package | Unit |
| Go API — integration | Go `testing` + `httptest` | Integration |
| Go API — reliability math | Go `testing` | Unit |
| Python poller | `pytest` | Unit |
| Vue web app | Playwright | End-to-End |
| Flutter mobile | Flutter test + integration_test | Unit + Widget + Integration |

---

## 2. Test Strategy

### 2.1 Testing Levels

```
┌─────────────────────────────────────────────┐
│         End-to-End Tests (Playwright)        │  Full user flows in browser
├─────────────────────────────────────────────┤
│       Integration Tests (httptest)           │  API handler + real DB
├─────────────────────────────────────────────┤
│         Unit Tests (go test / pytest)        │  Individual functions
└─────────────────────────────────────────────┘
```

### 2.2 Test Priorities

| Priority | Area | Rationale |
|----------|------|-----------|
| P1 — Critical | Auth (register, login, JWT) | Security; everything else depends on it |
| P1 — Critical | Reliability score formula | Core differentiating feature |
| P1 — Critical | Transit data endpoints | Primary user-facing functionality |
| P2 — High | Crowdsource reports + notifications | User trust feature |
| P2 — High | Trip planning | High-visibility demo feature |
| P3 — Medium | Favorites, settings | Nice-to-have user features |
| P3 — Medium | Weather, about/team | Supplementary features |

### 2.3 Pass/Fail Criteria

A test **passes** if the actual output exactly matches the expected output defined in each test case. A test **fails** if:
- The response status code differs from expected
- The response body is missing required fields
- An exception or panic occurs unexpectedly
- A UI element is absent or in the wrong state

### 2.4 Test Execution

- Unit and integration tests: run automatically in GitHub Actions on every pull request
- E2E tests: run automatically in GitHub Actions on merge to `main`
- Manual exploratory testing: performed by team members before each milestone demo

---

## 3. Test Environment

### 3.1 Backend Test Environment

| Item | Value |
|------|-------|
| Go version | 1.22+ |
| Test database (PostgreSQL) | Docker container on port 5433 (separate from dev) |
| Test database (MongoDB) | Docker container on port 27018 (separate from dev) |
| External APIs | Mocked using `net/http/httptest` or stub servers |
| Environment variables | Loaded from `.env.test` |
| Test command | `go test ./...` |

### 3.2 Web Test Environment

| Item | Value |
|------|-------|
| Browser | Chromium (Playwright default) |
| API backend | Running locally at `http://localhost:8080` |
| Test DB | Seeded test data |
| Test command | `npx playwright test` |
| Config | `playwright.config.ts` |

### 3.3 Mobile Test Environment

| Item | Value |
|------|-------|
| Flutter SDK | 3.3.0+ |
| Emulator | Android 8.0+ (API 26+) via Android Studio |
| iOS Simulator | iOS 14+ (for widget tests) |
| Test command | `flutter test` (unit/widget), `flutter test integration_test/` (integration) |
| Mock location | Set to Bellevue, WA (47.6101° N, 122.2015° W) |

### 3.4 Test Data Seeding

Before test runs, the following seed data is applied:

**PostgreSQL — `arrivals` table:**
- 200 synthetic records for stop `1_67652`, route `40`, spanning the last 90 days
- Delays ranging from -60s to +300s to produce a meaningful score
- Records distributed across all five time bins

**MongoDB:**
- 3 test user accounts (credentials in `.env.test`)
- 2 favorite routes for test user 1
- 5 vehicle reports for test user 1
- 3 notifications for test user 1 (2 unread, 1 read)
- Team collection seeded with 4 members

---

## 4. Unit Tests

### 4.1 Reliability Score Computation

**Module:** `api/internal/services/reliability_service.go`

---

**TC-U-001 — Score: perfect on-time record**

| Field | Value |
|-------|-------|
| Input | 100 arrivals all with `delay_seconds` in [-120, 120] |
| Expected | `score = 100`, `on_time_rate = 1.0`, `confidence > 0.9999` |
| FR | FR-402, FR-407 |

---

**TC-U-002 — Score: all arrivals severely late**

| Field | Value |
|-------|-------|
| Input | 50 arrivals all with `delay_seconds = 600` (10 min late) |
| Expected | `score < 30`, `on_time_rate = 0.0`, `mean_delay = 600` |
| FR | FR-402 |

---

**TC-U-003 — Score: mixed on-time and late**

| Field | Value |
|-------|-------|
| Input | 50 arrivals on-time, 50 arrivals 5 min late |
| Expected | `on_time_rate = 0.5`, `score` between 30 and 70 |
| FR | FR-402 |

---

**TC-U-004 — Confidence: zero samples**

| Field | Value |
|-------|-------|
| Input | `n = 0` |
| Expected | `confidence = 0.0` |
| FR | FR-407 |

---

**TC-U-005 — Confidence: 10 samples**

| Field | Value |
|-------|-------|
| Input | `n = 10` |
| Expected | `confidence = 1 - e^(-10/10) ≈ 0.632` |
| FR | FR-407 |

---

**TC-U-006 — Confidence: 50 samples**

| Field | Value |
|-------|-------|
| Input | `n = 50` |
| Expected | `confidence ≈ 0.993` |
| FR | FR-407 |

---

**TC-U-007 — 90-day window filter**

| Field | Value |
|-------|-------|
| Input | 100 arrivals in last 90 days, 50 arrivals older than 91 days |
| Expected | Score computed from exactly 100 records; old records excluded |
| FR | FR-403 |

---

**TC-U-008 — Time-bin filter: morning only**

| Field | Value |
|-------|-------|
| Input | 20 morning records (06:00–09:00), 30 afternoon records |
| Request | `timeBin = morning` |
| Expected | Score uses only 20 records; `n = 20` |
| FR | FR-404 |

---

**TC-U-009 — Day type filter: weekday only**

| Field | Value |
|-------|-------|
| Input | 40 weekday records, 20 weekend records |
| Request | `dayType = weekday` |
| Expected | Score uses only 40 records; `n = 40` |
| FR | FR-405 |

---

### 4.2 Auth Service

**Module:** `api/internal/services/authService.go`

---

**TC-U-010 — Register: valid credentials**

| Field | Value |
|-------|-------|
| Input | `email = test@example.com`, `password = password123` |
| Expected | User inserted in DB; returned token is valid JWT |
| FR | FR-1001, FR-1002, FR-1003 |

---

**TC-U-011 — Register: password too short**

| Field | Value |
|-------|-------|
| Input | `password = abc` (3 chars) |
| Expected | Error returned; no user inserted |
| FR | FR-1001 |

---

**TC-U-012 — Register: duplicate email**

| Field | Value |
|-------|-------|
| Input | Register with email already in DB |
| Expected | Error returned; HTTP 409 |
| FR | FR-1001 |

---

**TC-U-013 — Login: correct credentials**

| Field | Value |
|-------|-------|
| Input | Valid email and password |
| Expected | Valid JWT returned with `sub = userID` |
| FR | FR-1003 |

---

**TC-U-014 — Login: wrong password**

| Field | Value |
|-------|-------|
| Input | Correct email, wrong password |
| Expected | Error returned; no token issued |
| FR | FR-1003 |

---

**TC-U-015 — Login: non-existent email**

| Field | Value |
|-------|-------|
| Input | Email not in DB |
| Expected | Error returned; no token issued |
| FR | FR-1003 |

---

**TC-U-016 — Password hashed with bcrypt**

| Field | Value |
|-------|-------|
| Verification | After register, query DB: `passwordHash` must NOT equal plaintext password |
| Expected | `bcrypt.CompareHashAndPassword(hash, plaintext)` returns nil |
| FR | FR-1002 |

---

**TC-U-017 — JWT token structure**

| Field | Value |
|-------|-------|
| Input | Valid login |
| Expected | Token decodes to valid claims: `sub` = userID string, `exp` > now, algorithm = HS256 |
| FR | FR-1003 |

---

### 4.3 Transit Poller

**Module:** `transit-poller/poller.py`  
**Framework:** `pytest`

---

**TC-U-018 — Delay calculation: late bus**

| Field | Value |
|-------|-------|
| Input | `scheduled_ms = 1000000`, `predicted_ms = 1180000` |
| Expected | `delay_seconds = 180.0` |
| FR | FR-402 |

---

**TC-U-019 — Delay calculation: early bus**

| Field | Value |
|-------|-------|
| Input | `scheduled_ms = 1000000`, `predicted_ms = 940000` |
| Expected | `delay_seconds = -60.0` |
| FR | FR-402 |

---

**TC-U-020 — OBA API error handled gracefully**

| Field | Value |
|-------|-------|
| Input | Mock OBA endpoint returns HTTP 500 |
| Expected | Exception is caught; polling loop continues to next stop; no crash |
| FR | NFR-203 |

---

**TC-U-021 — DB insert error handled gracefully**

| Field | Value |
|-------|-------|
| Input | Mock PostgreSQL raises `OperationalError` on INSERT |
| Expected | Exception is caught and logged; loop continues on next cycle |
| FR | NFR-203 |

---

## 5. Integration Tests

Integration tests exercise the HTTP layer end-to-end using `net/http/httptest` with a real test database. Each test makes an actual HTTP request to the handler and checks the response.

### 5.1 Authentication Endpoints

---

**TC-I-001 — POST /auth/register → 201 Created**

| Step | Detail |
|------|--------|
| Request | `POST /api/v1/auth/register` `{"email":"new@test.com","password":"password123"}` |
| Expected status | 201 |
| Expected body | `{"token": "<jwt>", "user": {"email": "new@test.com", ...}}` |
| FR | FR-1001, FR-1003 |

---

**TC-I-002 — POST /auth/register → 409 duplicate email**

| Step | Detail |
|------|--------|
| Setup | Seed user with `existing@test.com` |
| Request | `POST /auth/register` `{"email":"existing@test.com","password":"password123"}` |
| Expected status | 409 |
| FR | FR-1001 |

---

**TC-I-003 — POST /auth/login → 200 with JWT**

| Step | Detail |
|------|--------|
| Setup | Seed user with known credentials |
| Request | `POST /auth/login` `{"email":"user@test.com","password":"password123"}` |
| Expected status | 200 |
| Expected body | `{"token": "<valid jwt>"}` |
| FR | FR-1003 |

---

**TC-I-004 — POST /auth/login → 401 wrong password**

| Step | Detail |
|------|--------|
| Request | `POST /auth/login` `{"email":"user@test.com","password":"wrongpassword"}` |
| Expected status | 401 |
| FR | FR-1003 |

---

### 5.2 Protected Endpoint Auth Enforcement

---

**TC-I-005 — GET /users/me → 401 without token**

| Step | Detail |
|------|--------|
| Request | `GET /api/v1/users/me` (no Authorization header) |
| Expected status | 401 |
| FR | FR-1005 |

---

**TC-I-006 — GET /users/me → 401 with expired token**

| Step | Detail |
|------|--------|
| Request | `GET /api/v1/users/me` with a JWT where `exp` is in the past |
| Expected status | 401 |
| FR | FR-1005 |

---

**TC-I-007 — GET /users/me → 200 with valid token**

| Step | Detail |
|------|--------|
| Request | `GET /api/v1/users/me` with valid JWT |
| Expected status | 200 |
| Expected body | `{"email": "...", "displayName": "...", "tempUnit": "F", ...}` |
| FR | FR-1101 |

---

### 5.3 Transit Endpoints

---

**TC-I-008 — GET /transit/vehicles → 200 with vehicle array**

| Step | Detail |
|------|--------|
| Setup | Mock GTFS-RT feed returns 3 vehicles |
| Request | `GET /api/v1/transit/vehicles` |
| Expected status | 200 |
| Expected body | Array of 3 vehicle objects each with `vehicleId`, `lat`, `lng`, `routeId`, `bearing` |
| FR | FR-102 |

---

**TC-I-009 — GET /transit/stops/nearby → 200**

| Step | Detail |
|------|--------|
| Setup | Mock OBA response with 5 stops |
| Request | `GET /api/v1/transit/stops/nearby?lat=47.61&lng=-122.20&radius=500` |
| Expected status | 200 |
| Expected body | Array of stop objects each with `stopId`, `name`, `lat`, `lng` |
| FR | FR-201 |

---

**TC-I-010 — GET /transit/stops/:id/arrivals → 200**

| Step | Detail |
|------|--------|
| Setup | Mock OBA response with 4 arrivals for stop `1_67652` |
| Request | `GET /api/v1/transit/stops/1_67652/arrivals` |
| Expected status | 200 |
| Expected body | Array of arrival objects with `routeId`, `headsign`, `scheduledTime`, `predictedTime` |
| FR | FR-301 |

---

### 5.4 Reliability Endpoints

---

**TC-I-011 — GET /reliability/stop/:id → 200 with score**

| Step | Detail |
|------|--------|
| Setup | PostgreSQL seeded with 200 arrival records for stop `1_67652` / route `40` |
| Request | `GET /api/v1/reliability/stop/1_67652?routeId=40` |
| Expected status | 200 |
| Expected body | `{"score": <0-100>, "onTimeRate": <0-1>, "meanDelay": <float>, "confidence": <0-1>}` |
| FR | FR-401, FR-402 |

---

**TC-I-012 — GET /reliability/stop/:id → 200 empty data**

| Step | Detail |
|------|--------|
| Setup | No records in PostgreSQL for stop `9_99999` |
| Request | `GET /api/v1/reliability/stop/9_99999?routeId=999` |
| Expected status | 200 |
| Expected body | `{"score": 0, "confidence": 0, "n": 0}` |
| FR | FR-407 |

---

**TC-I-013 — GET /reliability/predict → 200**

| Step | Detail |
|------|--------|
| Request | `GET /api/v1/reliability/predict?stopId=1_67652&routeId=40&timeBin=morning` |
| Expected status | 200 |
| Expected body | `{"meanDelay": <float>, "p90Delay": <float>, "confidence": <float>}` |
| FR | FR-408 |

---

### 5.5 Crowdsource Endpoints

---

**TC-I-014 — POST /vehicle-reports/crowding → 201**

| Step | Detail |
|------|--------|
| Auth | Valid JWT for test user |
| Request | `POST /api/v1/vehicle-reports/crowding` `{"routeId":"40","vehicleId":"1234","level":4}` |
| Expected status | 201 |
| DB verification | New document in `vehicle_reports` with `type="crowding"`, `level=4`, `userID=<test user>` |
| FR | FR-702 |

---

**TC-I-015 — POST /vehicle-reports/crowding → 401 unauthenticated**

| Step | Detail |
|------|--------|
| Auth | No JWT |
| Request | `POST /api/v1/vehicle-reports/crowding` `{...}` |
| Expected status | 401 |
| FR | FR-1005 |

---

**TC-I-016 — GET /vehicle-reports/mine → only own reports**

| Step | Detail |
|------|--------|
| Setup | User A has 3 reports; User B has 2 reports |
| Auth | JWT for User A |
| Request | `GET /api/v1/vehicle-reports/mine` |
| Expected status | 200 |
| Expected body | Array of exactly 3 reports, all with `userID = User A` |
| FR | FR-706 |

---

**TC-I-017 — DELETE /vehicle-reports/:id → User A cannot delete User B's report**

| Step | Detail |
|------|--------|
| Setup | Report owned by User B |
| Auth | JWT for User A |
| Request | `DELETE /api/v1/vehicle-reports/<user B's report id>` |
| Expected status | 403 or 404 |
| FR | FR-707 |

---

### 5.6 Favorites Endpoints

---

**TC-I-018 — POST /users/me/favorites → 201**

| Step | Detail |
|------|--------|
| Auth | Valid JWT |
| Request | `POST /api/v1/users/me/favorites` `{"label":"Home→Work","origin":{...},"destination":{...}}` |
| Expected status | 201 |
| Expected body | Created favorite with `_id` assigned |
| FR | FR-1201 |

---

**TC-I-019 — GET /users/me/favorites → own favorites only**

| Step | Detail |
|------|--------|
| Setup | User A has 2 favorites; User B has 3 favorites |
| Auth | JWT for User A |
| Request | `GET /api/v1/users/me/favorites` |
| Expected status | 200 |
| Expected body | Array of exactly 2 favorites |
| FR | FR-1202 |

---

**TC-I-020 — DELETE /users/me/favorites/:id → 204**

| Step | Detail |
|------|--------|
| Setup | User A has a favorite with known ID |
| Auth | JWT for User A |
| Request | `DELETE /api/v1/users/me/favorites/<id>` |
| Expected status | 204 |
| DB verification | Favorite no longer in collection |
| FR | FR-1203 |

---

### 5.7 Notifications Endpoints

---

**TC-I-021 — Notification fan-out on report submission**

| Step | Detail |
|------|--------|
| Setup | User B has favorite with `transitRouteIds: ["40"]` |
| Auth | JWT for User A |
| Action | User A submits crowding report for route `40` |
| Expected | Notification document created in MongoDB for User B |
| FR | FR-1301 |

---

**TC-I-022 — GET /notifications → unread count**

| Step | Detail |
|------|--------|
| Setup | 2 unread, 1 read notifications for test user |
| Auth | Valid JWT |
| Request | `GET /api/v1/notifications` |
| Expected | `{"notifications": [...], "unreadCount": 2}` |
| FR | FR-1302 |

---

**TC-I-023 — PATCH /notifications/read-all → all marked read**

| Step | Detail |
|------|--------|
| Setup | 3 unread notifications |
| Auth | Valid JWT |
| Request | `PATCH /api/v1/notifications/read-all` |
| Expected status | 200 |
| Follow-up | GET /notifications → `unreadCount = 0` |
| FR | FR-1304 |

---

### 5.8 User Settings

---

**TC-I-024 — PUT /users/me/settings → tempUnit updated**

| Step | Detail |
|------|--------|
| Auth | Valid JWT |
| Request | `PUT /api/v1/users/me/settings` `{"tempUnit":"C"}` |
| Expected status | 200 |
| Follow-up | GET /users/me → `"tempUnit": "C"` |
| FR | FR-1103 |

---

**TC-I-025 — DELETE /users/me → account soft-deleted**

| Step | Detail |
|------|--------|
| Auth | Valid JWT |
| Request | `DELETE /api/v1/users/me` |
| Expected status | 200 |
| DB verification | User document has `"deleted": true` |
| FR | FR-1007 |

---

### 5.9 Service Alerts

---

**TC-I-026 — GET /service-alerts → 200 with alerts array**

| Step | Detail |
|------|--------|
| Setup | Mock both GTFS-RT alert feeds with 2 alerts each |
| Request | `GET /api/v1/service-alerts` |
| Expected status | 200 |
| Expected body | Array of 4 alerts each with `agency`, `effect`, `headerText` |
| FR | FR-801 |

---

**TC-I-027 — GET /service-alerts → 200 empty when feed unavailable**

| Step | Detail |
|------|--------|
| Setup | Both GTFS-RT feeds return connection error |
| Request | `GET /api/v1/service-alerts` |
| Expected status | 200 |
| Expected body | `{"alerts": []}` (graceful degradation, not 500) |
| FR | NFR-202 |

---

## 6. End-to-End Tests

E2E tests use Playwright against a running dev stack. Test IDs correspond to user-visible flows.

### 6.1 Authentication Flows

---

**TC-E-001 — Register new account**

```
1. Navigate to /register
2. Fill email: "e2e-test@soundsync.test", password: "password123", confirm: "password123"
3. Click "Register"
Expected: Redirected to /, nav bar shows user display name, no login button visible
FR: FR-1001, FR-1003
```

---

**TC-E-002 — Login with existing account**

```
1. Navigate to /login
2. Fill email and password for seeded test user
3. Click "Sign In"
Expected: Redirected to /, notification badge visible in nav
FR: FR-1003
```

---

**TC-E-003 — Protected route redirect**

```
1. While logged out, navigate directly to /account
Expected: Redirected to /login
FR: FR-1005
```

---

**TC-E-004 — Logout**

```
1. Log in
2. Open account menu → click Logout
Expected: Token cleared; nav shows login/register links; /account redirects to /login
FR: FR-1006
```

---

### 6.2 Live Map

---

**TC-E-005 — Map loads with vehicle markers**

```
1. Navigate to /
Expected: Google Map renders (canvas/iframe visible)
         At least 1 vehicle marker visible within 5 seconds
         No console errors
FR: FR-101, FR-102
```

---

**TC-E-006 — Click vehicle marker opens detail panel**

```
1. Navigate to /
2. Wait for vehicle marker(s) to appear
3. Click a vehicle marker
Expected: Detail panel appears showing routeId, vehicleId, occupancy status
FR: FR-104
```

---

**TC-E-007 — Click stop marker opens arrival board**

```
1. Navigate to /
2. Click a stop marker on the map
Expected: Arrival board appears listing at least 1 upcoming arrival
         Each arrival shows route number, headsign, scheduled time
FR: FR-105, FR-301, FR-302, FR-303
```

---

**TC-E-008 — Map auto-refreshes vehicles**

```
1. Note vehicle positions at time T
2. Wait 16 seconds
Expected: Vehicle positions have updated (markers moved or new ones appeared)
FR: FR-102
```

---

### 6.3 Trip Planning

---

**TC-E-009 — Plan a trip from origin to destination**

```
1. Navigate to /
2. Enter "Bellevue Transit Center" in origin field
3. Enter "Seattle Westlake Station" in destination field
4. Click "Plan Trip" / "Get Directions"
Expected: At least 1 route option displayed showing total time, transit legs
          Route polyline rendered on map
FR: FR-501, FR-502, FR-503, FR-504
```

---

**TC-E-010 — Chatbot auto-fills trip and triggers directions**

```
1. Navigate to /
2. Click chatbot icon
3. Type: "How do I get from Bellevue to downtown Seattle?"
4. Wait for chatbot response
Expected: Chatbot replies with route suggestion
          Origin/destination fields auto-populate
          Route planning automatically triggers (route shown on map)
FR: FR-601, FR-604, FR-607
```

---

### 6.4 Reliability Scores

---

**TC-E-011 — Score page loads**

```
1. Navigate to /score
Expected: Page loads with at least 1 reliability score card
          Each card shows numeric score and color indicator
          Green card has score >= 80, yellow 50-79, red < 50
FR: FR-401, FR-406, FR-409
```

---

**TC-E-012 — Reliability badge appears on arrival board**

```
1. Click a stop marker to open arrival board
2. Verify each arrival row
Expected: Reliability badge visible next to each arrival showing score 0–100
          Badge color matches score range (green/yellow/red)
FR: FR-406
```

---

### 6.5 Crowdsourced Reports

---

**TC-E-013 — Submit crowding report (authenticated)**

```
1. Log in as test user
2. Navigate to / → click a vehicle marker
3. Click "Report Issue" or report icon
4. Select "Crowding" → level 4 → Submit
Expected: Success toast message appears
          Report appears in GET /vehicle-reports/mine response
FR: FR-702, FR-705
```

---

**TC-E-014 — Report button not visible when logged out**

```
1. Log out
2. Click a vehicle marker
Expected: Report submission button is absent or disabled
FR: FR-702
```

---

### 6.6 Service Alerts

---

**TC-E-015 — Service alert badge visible**

```
1. Navigate to /
Expected: Alert bell icon visible in header
          If alerts exist, badge shows count > 0
FR: FR-803
```

---

**TC-E-016 — Alert dropdown opens**

```
1. Click alert bell icon
Expected: Dropdown opens listing active alerts
          Each alert shows agency, effect, header text
FR: FR-802, FR-803
```

---

### 6.7 Weather Widget

---

**TC-E-017 — Weather widget displays**

```
1. Navigate to /
Expected: WeatherWidget visible on map overlay
          Shows temperature and conditions description
          Temperature displayed in °F (default)
FR: FR-901
```

---

**TC-E-018 — Temperature unit respects user setting**

```
1. Log in → go to /account → set temperature unit to "°C" → save
2. Navigate to /
Expected: WeatherWidget shows temperature in °C
FR: FR-904, FR-1103
```

---

### 6.8 Favorites

---

**TC-E-019 — Save and load a favorite route**

```
1. Log in
2. Plan a trip (origin → destination)
3. Click "Save as Favorite" → label "Work Commute" → Save
4. Navigate to /account → Favorites tab
Expected: "Work Commute" appears in favorites list
5. Click "Work Commute"
Expected: Trip planning panel populates with saved origin and destination
FR: FR-1201, FR-1202, FR-1204
```

---

**TC-E-020 — Delete a favorite**

```
1. Log in → navigate to favorites
2. Click delete on a saved favorite → confirm
Expected: Favorite removed from list; no longer appears after page refresh
FR: FR-1203
```

---

### 6.9 Notifications

---

**TC-E-021 — Unread notification count badge**

```
1. Log in as User B (who has 2 unread notifications seeded)
Expected: Notification badge in nav bar shows "2"
FR: FR-1305
```

---

**TC-E-022 — Mark all read clears badge**

```
1. Log in with user having unread notifications
2. Open notification panel → click "Mark all as read"
Expected: Badge disappears or shows "0"
FR: FR-1304
```

---

### 6.10 About Page

---

**TC-E-023 — About page shows team members**

```
1. Navigate to /about
Expected: Page loads; 4 team member cards visible
          Each card shows name and role
          Data loaded dynamically from /api/v1/team
FR: FR-1501, FR-1502
```

---

## 7. Performance Tests

### 7.1 API Response Time

Tests use `wrk` or Go's `testing.B` benchmarks against a local instance with seeded test data.

---

**TC-P-001 — Vehicle endpoint under load**

| Config | Value |
|--------|-------|
| Tool | `wrk -t4 -c50 -d30s` |
| Target | `GET /api/v1/transit/vehicles` |
| Acceptance | p95 latency < 500ms; 0 errors |
| FR | NFR-101 |

---

**TC-P-002 — Reliability score query**

| Config | Value |
|--------|-------|
| Tool | Go benchmark `BenchmarkGetStopReliability` |
| Setup | 200 PostgreSQL records for stop/route |
| Acceptance | Single query completes < 2000ms |
| FR | NFR-105 |

---

**TC-P-003 — Concurrent authenticated requests**

| Config | Value |
|--------|-------|
| Tool | `wrk -t4 -c100 -d30s` with JWT header |
| Target | `GET /api/v1/users/me` |
| Acceptance | p95 latency < 500ms; no 5xx responses |
| FR | NFR-101 |

---

**TC-P-004 — Web app initial load**

| Config | Value |
|--------|-------|
| Tool | Lighthouse CLI or Playwright `performance` API |
| Target | `/` on production build |
| Acceptance | LCP (Largest Contentful Paint) < 3000ms on simulated 10 Mbps |
| FR | NFR-104 |

---

**TC-P-005 — Transit poller cycle time**

| Config | Value |
|--------|-------|
| Method | Log timestamps before and after each OBA poll + INSERT batch |
| Acceptance | Full cycle for 4 stops completes in < 60s |
| FR | NFR-103 |

---

## 8. Security Tests

---

**TC-S-001 — JWT with wrong secret rejected**

| Step | Detail |
|------|--------|
| Input | Token signed with a different secret key |
| Request | `GET /api/v1/users/me` |
| Expected | 401 Unauthorized |
| FR | NFR-305 |

---

**TC-S-002 — Expired JWT rejected**

| Step | Detail |
|------|--------|
| Input | Token with `exp` set to 1 second in the past |
| Request | `GET /api/v1/users/me` |
| Expected | 401 Unauthorized |
| FR | NFR-305 |

---

**TC-S-003 — Password not stored in plaintext**

| Step | Detail |
|------|--------|
| Action | Register user; query MongoDB `users` collection directly |
| Expected | `passwordHash` field does NOT match plaintext password; starts with `$2a$` (bcrypt prefix) |
| FR | NFR-303, FR-1002 |

---

**TC-S-004 — CORS rejects unknown origin**

| Step | Detail |
|------|--------|
| Request | Any API endpoint with `Origin: https://attacker.example.com` |
| Expected | Response does NOT include `Access-Control-Allow-Origin: https://attacker.example.com` |
| FR | NFR-304 |

---

**TC-S-005 — SQL injection in stop ID parameter**

| Step | Detail |
|------|--------|
| Request | `GET /api/v1/reliability/stop/1' OR '1'='1` |
| Expected | 400 Bad Request or safe empty result; no DB error leaks in response; no data exfiltration |
| FR | NFR-306 |

---

**TC-S-006 — XSS in report description**

| Step | Detail |
|------|--------|
| Auth | Valid JWT |
| Request | `POST /reports` with `description: "<script>alert('xss')</script>"` |
| Expected | Script tags stored as escaped string or sanitized; not executed when rendered in UI |
| FR | NFR-306 |

---

**TC-S-007 — User cannot read another user's data**

| Step | Detail |
|------|--------|
| Auth | JWT for User A |
| Request | `GET /api/v1/notifications` |
| Expected | Only User A's notifications returned; User B's notifications absent |
| FR | NFR-305 |

---

**TC-S-008 — .env not accessible via web server**

| Step | Detail |
|------|--------|
| Request | `GET /.env` or `GET /api/.env` on production URL |
| Expected | 404 Not Found; no secret values returned |
| FR | NFR-307 |

---

## 9. Mobile-Specific Tests

Flutter test framework: `flutter_test` (unit/widget), `integration_test` (on-device).

---

**TC-M-001 — App launches without crash**

```
flutter test integration_test/app_test.dart

1. Launch app on emulator
Expected: App loads to home screen or login screen within 5 seconds
          No unhandled exceptions in flutter logs
FR: FR-1401
```

---

**TC-M-002 — GPS location requested on home screen**

```
Widget test: home_screen_test.dart

1. Mock Geolocator to return position (47.6101, -122.2015)
2. Render HomeScreen
Expected: Map centers on mocked GPS position
          No error shown to user
FR: FR-1402
```

---

**TC-M-003 — Bottom navigation switches screens**

```
Widget test: main_shell_test.dart

1. Render MainShell
2. Tap "Chat" in bottom nav
Expected: ChatScreen visible
3. Tap "Scores"
Expected: ScoresScreen visible
4. Tap "Account"
Expected: AccountScreen visible (or redirect to login if not authenticated)
FR: FR-1403
```

---

**TC-M-004 — Token persisted across app restarts**

```
Integration test:

1. Log in as test user
2. Force-kill and relaunch app
Expected: User is still logged in (not redirected to login screen)
          Secure storage preserved JWT token
FR: FR-1404
```

---

**TC-M-005 — Login flow on mobile**

```
Integration test:

1. Launch app while logged out
2. Tap login link
3. Enter credentials → tap Sign In
Expected: Navigated to home screen; bottom nav visible
FR: FR-1405
```

---

**TC-M-006 — Dark theme applied**

```
Widget test:

1. Render any screen
Expected: Scaffold background color matches #0D1B2A
          Primary color matches #7FDBFF
FR: FR-1406
```

---

**TC-M-007 — Vehicle markers visible on mobile map**

```
Integration test:

1. Mock GET /transit/vehicles to return 3 vehicles
2. Navigate to home screen
Expected: 3 markers rendered on GoogleMap widget
FR: FR-102, FR-1401
```

---

**TC-M-008 — Chatbot accessible from bottom nav**

```
Integration test:

1. Tap "Chat" in bottom nav
Expected: ChatScreen loads
2. Type a message and tap send
Expected: Loading indicator shown; response displayed within 10 seconds
FR: FR-601, FR-1401
```

---

## 10. Test Results and Acceptance Criteria

### 10.1 Acceptance Criteria Summary

The system is considered ready for demo / release when:

| Criterion | Target |
|-----------|--------|
| Unit tests passing | 100% of TC-U-001 through TC-U-021 |
| Integration tests passing | 100% of TC-I-001 through TC-I-027 |
| E2E tests passing | ≥ 90% of TC-E-001 through TC-E-023 (known flaky tests may be skipped with documented justification) |
| Performance — API p95 | < 500ms under 100 concurrent users |
| Performance — reliability query | < 2000ms single call |
| Performance — web LCP | < 3000ms |
| Security tests | 100% of TC-S-001 through TC-S-008 pass |
| Mobile tests | 100% of TC-M-001 through TC-M-008 pass |
| No P1 open bugs | Zero critical bugs blocking core user flows |

### 10.2 Known Limitations and Deferred Tests

| Item | Reason Deferred |
|------|----------------|
| GTFS-RT live feed tests | Live feeds are not mocked consistently; covered by manual exploratory testing |
| Password reset flow | Feature not implemented in v1.0 |
| Load test > 100 concurrent users | Out of scope for academic capstone; single-instance deployment assumed |
| iOS on-device integration tests | Requires Mac build host; not available in CI environment |
| Offline / no-network mode | App degrades gracefully but not formally tested |

### 10.3 Test Execution Log Template

For each test run, record:

```
Date:          YYYY-MM-DD
Tester:        [Name]
Environment:   [local / CI / staging]
Branch:        [branch name]
Commit:        [short SHA]

Results:
  Unit tests:        PASSED [ ] / FAILED [ ]   Count: ___/___
  Integration tests: PASSED [ ] / FAILED [ ]   Count: ___/___
  E2E tests:         PASSED [ ] / FAILED [ ]   Count: ___/___
  Performance:       PASSED [ ] / FAILED [ ]
  Security:          PASSED [ ] / FAILED [ ]
  Mobile:            PASSED [ ] / FAILED [ ]

Failures (list TC IDs and brief description):
  -
  -

Overall: PASS [ ] / FAIL [ ]
Sign-off: ________________________
```

### 10.4 Bug Severity Classification

| Severity | Definition | Example |
|----------|-----------|---------|
| P1 — Critical | Core feature broken; no workaround | Login fails for all users |
| P2 — High | Major feature degraded; workaround exists | Reliability scores show 0 for all routes |
| P3 — Medium | Minor feature issue; user not blocked | Notification badge shows wrong count |
| P4 — Low | Cosmetic or edge case | Weather icon misaligned on certain screen sizes |

P1 and P2 bugs must be resolved before demo sign-off. P3 and P4 bugs are documented and deferred to post-capstone.

---

*End of Software Test Document*
