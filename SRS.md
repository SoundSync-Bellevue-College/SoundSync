# Software Requirements Specification
## SoundSync — Real-Time Seattle Transit Application

**Version:** 1.0  
**Date:** 2026-06-18  
**Course:** CS 481 — Capstone 1, Bellevue College  
**Team:** Abshira Salat, Wayne San, Nolan, Tony  

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [User Classes and Characteristics](#3-user-classes-and-characteristics)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [System Architecture](#7-system-architecture)
8. [Data Requirements](#8-data-requirements)
9. [Constraints and Assumptions](#9-constraints-and-assumptions)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) describes the functional and non-functional requirements for **SoundSync**, a real-time Seattle-area public transit application. It is intended for the development team, project stakeholders, and academic evaluators for Bellevue College CS 481 Capstone 1.

### 1.2 Scope

SoundSync is a full-stack transit application consisting of:

- A **web application** (Vue 3 + TypeScript) for browser-based access
- A **mobile application** (Flutter) for iOS and Android devices
- A **REST API backend** (Go) serving both clients
- A **transit data poller** (Python) that continuously collects OneBusAway arrival data
- Two **databases**: PostgreSQL (arrival history) and MongoDB (user data)

The system provides Seattle-area riders with live bus positions, AI-powered reliability scores, trip planning, crowdsourced vehicle reports, service alerts, weather integration, and an AI transit chatbot.

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|------|-----------|
| OBA | OneBusAway — open-source transit tracking platform used by King County Metro and Sound Transit |
| GTFS | General Transit Feed Specification — standardized format for transit schedule data |
| GTFS-RT | GTFS-Realtime — extension for live vehicle positions, trip updates, and service alerts |
| JWT | JSON Web Token — stateless authentication token |
| API | Application Programming Interface |
| SRS | Software Requirements Specification |
| ML | Machine Learning |
| UI | User Interface |
| CI/CD | Continuous Integration / Continuous Deployment |
| FR | Functional Requirement |
| NFR | Non-Functional Requirement |

### 1.4 References

- OneBusAway REST API documentation
- Sound Transit GTFS-Realtime feeds
- King County Metro GTFS-Realtime feeds
- Google Maps Platform API documentation
- Anthropic Claude API documentation
- NOAA Weather API / OpenWeatherMap API documentation
- IEEE 830-1998: Recommended Practice for Software Requirements Specifications

### 1.5 Overview

Section 2 describes the product context and overall functions. Section 3 defines user classes. Sections 4 and 5 detail functional and non-functional requirements. Sections 6–9 cover interfaces, architecture, data, and constraints.

---

## 2. Overall Description

### 2.1 Product Perspective

SoundSync is a new, standalone system that aggregates data from multiple third-party transit and weather APIs into a unified rider-facing experience. It does not replace OneBusAway or Sound Transit's own apps — instead it layers AI-powered reliability prediction and crowdsourced community reporting on top of existing real-time data.

```
┌─────────────────────────────────────────────────────┐
│                   Client Layer                      │
│   Web App (Vue 3)          Mobile App (Flutter)     │
└───────────────────┬─────────────────────────────────┘
                    │ HTTPS / REST
┌───────────────────▼─────────────────────────────────┐
│               Go REST API (Port 8080)               │
└──┬────────────┬──────────────┬───────────┬──────────┘
   │            │              │           │
┌──▼───┐  ┌────▼─────┐  ┌─────▼──┐  ┌────▼────────┐
│ OBA  │  │  GTFS-RT │  │Google  │  │  Anthropic  │
│ API  │  │  Feeds   │  │  Maps  │  │  Claude API │
└──────┘  └──────────┘  └────────┘  └─────────────┘
   │
┌──▼──────────────────┐    ┌──────────────────────────┐
│  PostgreSQL          │    │  MongoDB                 │
│  (arrival history)   │◄───│  (users, reports, notifs)│
└──────────────────────┘    └──────────────────────────┘
          ▲
┌─────────┴────────────┐
│  Python Transit       │
│  Poller (60s interval)│
└──────────────────────┘
```

### 2.2 Product Functions Summary

- Live interactive map showing real-time bus positions
- Buses-near-you list with occupancy and route information
- AI-powered reliability scores (0–100) per route and stop combination
- Time-of-day reliability breakdowns (morning, midday, afternoon, evening, night)
- Trip planning with multi-modal route suggestions
- AI chatbot for natural-language transit assistance
- Crowdsourced vehicle reports (cleanliness, crowding, delays)
- Service alert aggregation from Sound Transit and King County Metro
- Real-time weather at any map location
- User accounts with favorites, notifications, and preference settings
- Mobile app with native GPS and gesture support

### 2.3 Operating Environment

| Component | Environment |
|-----------|-------------|
| Web frontend | Modern browsers (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+) |
| Mobile app | iOS 12+ and Android 8.0+ via Flutter |
| Backend API | Linux-based server or Docker container, Go 1.22+ |
| Transit poller | Python 3.12+, Docker container |
| Databases | PostgreSQL 16, MongoDB 7.0 |
| Deployment | AWS Amplify (frontend), Docker Compose (local dev) |
| CI/CD | GitHub Actions |

---

## 3. User Classes and Characteristics

### 3.1 Guest Rider (Unauthenticated)

A transit rider visiting the site or app without an account. Has read-only access to all public features. Cannot save preferences, submit reports, or receive notifications.

**Typical goals:** Check if a bus is running on time; plan a trip; see if a route is crowded.

### 3.2 Registered Rider (Authenticated)

A rider with a SoundSync account. Has all Guest capabilities plus personalization and contribution features.

**Typical goals:** Save favorite routes; receive alerts when a report is filed on a favorited route; submit crowdsource reports; track personal report history.

### 3.3 System Administrator

A developer or operations role with direct database and server access. Not represented by a UI persona — interacts through the backend directly.

---

## 4. Functional Requirements

Requirements are grouped by feature area. Each requirement is identified with a unique ID (FR-XXX).

---

### 4.1 Live Map

**FR-101** The system shall display an interactive map centered on the Seattle–Bellevue metro area.

**FR-102** The system shall fetch and display live bus vehicle positions from Sound Transit GTFS-Realtime feeds, refreshing every 15 seconds.

**FR-103** Each vehicle marker on the map shall encode the vehicle's bearing (direction of travel) visually.

**FR-104** Clicking a vehicle marker shall display a detail panel showing: route ID, trip ID, vehicle ID, occupancy status, and timestamp of last position update.

**FR-105** The system shall display transit stop markers on the map. Clicking a stop marker shall open an arrival board showing predicted arrivals for that stop.

**FR-106** The system shall display the selected route's polyline (shape) on the map when a route is active.

**FR-107** The map shall support pan, zoom, and click interactions on both desktop and mobile.

---

### 4.2 Buses Near You

**FR-201** The system shall display a list of buses currently operating within 0.5 miles of the map center.

**FR-202** If fewer than 2 buses are found within 0.5 miles, the system shall automatically expand the search radius to 1 mile.

**FR-203** Each entry in the buses-near-you list shall display: route number, headsign/destination, distance from center, and occupancy status.

**FR-204** Selecting a bus from the list shall center the map on that vehicle and open its detail panel.

---

### 4.3 Arrival Board

**FR-301** The system shall query the OneBusAway API to retrieve scheduled and predicted arrival times for a selected stop.

**FR-302** Arrival times shall be displayed as minutes-until-arrival relative to the current time.

**FR-303** The arrival board shall display: route number, headsign, scheduled time, predicted time, and delay status (early / on time / delayed).

**FR-304** Arrival data shall refresh automatically every 30 seconds while the stop panel is open.

---

### 4.4 Reliability Scores

**FR-401** The system shall compute and store reliability scores for route–stop combinations using historical arrival data from the PostgreSQL database.

**FR-402** Reliability scores shall be computed using the following weighted formula:

```
score = (on_time_rate × 50) + (consistency_score × 30) + (delay_score × 20)
```

Where:
- `on_time_rate` = fraction of arrivals within ±2 minutes of schedule
- `consistency_score` = 1 − (stddev_delay / max_expected_stddev), capped [0, 1]
- `delay_score` = max(0, 1 − mean_delay_seconds / max_expected_delay)

**FR-403** Scores shall be based on a rolling 90-day lookback window.

**FR-404** Scores shall be segmented by time-of-day bin: morning (06:00–09:00), midday (09:00–15:00), afternoon (15:00–18:00), evening (18:00–21:00), night (21:00–06:00).

**FR-405** Scores shall be segmented by day type: weekday (Mon–Fri) and weekend (Sat–Sun).

**FR-406** The UI shall display reliability scores color-coded as: green (≥80), yellow (50–79), red (<50).

**FR-407** The system shall compute a confidence score for each reliability estimate:

```
confidence = 1 - e^(-n / 10)
```

Where `n` is the number of arrival samples used.

**FR-408** The system shall provide a predicted delay for the next arrival, including mean delay and 90th-percentile delay, from the matching time bin.

**FR-409** A dedicated Scores page shall display an overview of reliability scores across multiple routes.

---

### 4.5 Trip Planning

**FR-501** The system shall accept an origin and destination (as text addresses or coordinates) and return one or more transit route options.

**FR-502** Route planning shall use the Google Directions API with transit mode.

**FR-503** Each route option shall display: total travel time, number of transfers, transit legs (route number, boarding stop, alighting stop, departure time), and walking legs.

**FR-504** The planned route shall be rendered as a polyline on the map.

**FR-505** The system shall allow users to input origin/destination via the map (click to set) or a text search field with autocomplete.

---

### 4.6 AI Chatbot

**FR-601** The system shall provide a conversational chatbot interface accessible on both web and mobile platforms.

**FR-602** The chatbot shall use the Anthropic Claude API (model: `claude-haiku-4-5-20251001`) with a transit-specific system prompt.

**FR-603** The system prompt shall instruct the model to act as a Seattle transit assistant and have knowledge of routes, reliability, and trip planning within the service area.

**FR-604** The chatbot shall be able to interpret a natural-language destination request and populate the trip planning origin/destination fields automatically.

**FR-605** On mobile web, the chatbot icon shall be visible and positioned to avoid overlapping other UI controls.

**FR-606** The chatbot conversation panel shall open in a direction that does not obscure the map (downward on mobile, or in a side drawer on desktop).

**FR-607** When the chatbot auto-fills a route, the system shall automatically trigger the trip planning directions flow.

---

### 4.7 Crowdsourced Vehicle Reports

**FR-701** Authenticated users shall be able to submit a **cleanliness report** for a vehicle, rated on a 1–5 scale.

**FR-702** Authenticated users shall be able to submit a **crowding report** for a vehicle, rated on a 1–5 scale.

**FR-703** Authenticated users shall be able to submit a **delay report** for a vehicle, rated on a 1–5 scale.

**FR-704** Authenticated users shall be able to submit a **general condition report** including: route ID, vehicle ID, report type, severity, description, and location.

**FR-705** The system shall display an aggregated crowdsource summary for a given stop or route, showing mean cleanliness, crowding, and delay scores.

**FR-706** Authenticated users shall be able to view the list of their own submitted reports.

**FR-707** Authenticated users shall be able to delete their own reports.

---

### 4.8 Service Alerts

**FR-801** The system shall fetch active service alerts from Sound Transit and King County Metro GTFS-Realtime alert feeds.

**FR-802** Each alert shall display: agency, effect, cause, header text, description, severity level, and active time period.

**FR-803** Alerts shall be displayed in a dropdown/banner accessible from the main navigation.

**FR-804** A per-stop alert banner shall display any active alerts relevant to the selected stop.

**FR-805** Alert data shall refresh on page load and on a timed interval while the app is active.

---

### 4.9 Weather

**FR-901** The system shall display current weather conditions for the current map viewport center, including: temperature, conditions description, and weather icon.

**FR-902** The system shall display an hourly weather forecast for the next several hours.

**FR-903** Weather data shall be sourced from NOAA or OpenWeatherMap APIs.

**FR-904** Users shall be able to configure their preferred temperature unit (Fahrenheit / Celsius) in account settings, and the weather widget shall respect this setting.

---

### 4.10 User Authentication

**FR-1001** The system shall allow new users to register with an email address and password. Passwords must be at least 8 characters.

**FR-1002** The system shall store passwords as bcrypt hashes; plaintext passwords shall never be persisted.

**FR-1003** Upon successful login, the system shall return a signed JWT token with an appropriate expiration.

**FR-1004** The JWT token shall be transmitted as a Bearer token in the `Authorization` header on all authenticated API requests.

**FR-1005** Authenticated routes shall return HTTP 401 if the token is missing, expired, or invalid.

**FR-1006** The system shall provide a logout mechanism that clears the stored token on the client.

**FR-1007** The system shall support account deletion (soft-delete); deleted accounts shall be flagged but data retained for audit.

---

### 4.11 User Account and Settings

**FR-1101** Authenticated users shall be able to view and update their display name.

**FR-1102** Authenticated users shall be able to toggle push/in-app notifications on or off.

**FR-1103** Authenticated users shall be able to set preferred temperature unit (°F / °C).

**FR-1104** Authenticated users shall be able to set preferred distance unit (miles / kilometers).

**FR-1105** The system shall persist these preferences server-side and apply them across sessions and devices.

---

### 4.12 Favorite Routes

**FR-1201** Authenticated users shall be able to save a favorite route pair consisting of: a label, an origin place reference, a destination place reference, and zero or more associated transit route IDs.

**FR-1202** Authenticated users shall be able to view their list of saved favorite routes.

**FR-1203** Authenticated users shall be able to delete a saved favorite route.

**FR-1204** Selecting a saved favorite route shall populate the trip planning panel with the saved origin and destination.

---

### 4.13 Notifications

**FR-1301** The system shall generate a notification for a user when a crowdsource report is filed on one of their favorited routes.

**FR-1302** Authenticated users shall be able to view a list of their unread and read notifications.

**FR-1303** Authenticated users shall be able to mark individual notifications as read.

**FR-1304** Authenticated users shall be able to mark all notifications as read at once.

**FR-1305** The navigation bar shall display an unread notification count badge.

---

### 4.14 Mobile Application

**FR-1401** The mobile app shall replicate all core public-facing features available on the web app: live map, buses near you, arrival boards, reliability scores, trip planning, chatbot, service alerts, and weather.

**FR-1402** The mobile app shall use the device's GPS to provide an accurate current location for the "near me" and trip planning features.

**FR-1403** The mobile app shall support swipe gestures for navigation between main sections (Home, Chat, Scores, Account).

**FR-1404** The mobile app shall store JWT tokens using platform-secure storage (`flutter_secure_storage`).

**FR-1405** The mobile app shall support the full authentication flow: register, login, logout, and account deletion.

**FR-1406** The mobile app shall apply a dark theme with primary color `#7FDBFF`, surface `#122340`, and background `#0D1B2A`.

---

### 4.15 Team / About Page

**FR-1501** The system shall provide an About page displaying project information and team member profiles.

**FR-1502** Team member data (name, role, bio, photo) shall be served dynamically from the backend API.

---

## 5. Non-Functional Requirements

### 5.1 Performance

**NFR-101** The API shall respond to 95% of requests within 500 ms under normal load (up to 100 concurrent users).

**NFR-102** Live vehicle position data shall be no more than 60 seconds stale on the client (15-second refresh interval plus network latency).

**NFR-103** The transit poller shall complete each polling cycle within 60 seconds and write results to PostgreSQL before the next cycle begins.

**NFR-104** The web app initial page load (LCP) shall complete within 3 seconds on a 10 Mbps connection.

**NFR-105** Reliability score queries shall return within 2 seconds for any route–stop–time-bin combination.

### 5.2 Reliability and Availability

**NFR-201** The backend API shall target 99% uptime during the academic term demo period.

**NFR-202** The system shall handle OBA API or GTFS feed unavailability gracefully, displaying a user-facing error message rather than crashing.

**NFR-203** The transit poller shall log errors and automatically retry on the next 60-second cycle if an OBA request fails.

**NFR-204** Database connection failures shall be caught and surfaced as HTTP 503 responses, not panics.

### 5.3 Security

**NFR-301** All API endpoints shall be served over HTTPS in production.

**NFR-302** JWT secrets shall be stored as environment variables and never committed to source control.

**NFR-303** Passwords shall be hashed with bcrypt (cost factor ≥ 10) before storage.

**NFR-304** The API shall enforce CORS, allowing requests only from known frontend origins (local dev and AWS Amplify production URLs).

**NFR-305** Authenticated endpoints shall validate the JWT on every request; expired tokens shall be rejected.

**NFR-306** User input (report descriptions, display names) shall be sanitized server-side to prevent injection attacks.

**NFR-307** The `.env` file containing API keys and secrets shall never be committed to the repository.

### 5.4 Usability

**NFR-401** The web app shall be usable on viewports from 375px (mobile) to 1920px (desktop) without horizontal scrolling.

**NFR-402** Color-coded reliability indicators shall also include text labels or icons to remain accessible to color-blind users.

**NFR-403** The chatbot shall respond within 5 seconds under normal network conditions.

**NFR-404** Error messages presented to users shall be human-readable and actionable (not raw stack traces or API error codes).

**NFR-405** The mobile app shall support system font scaling (accessibility text size settings) without layout breakage.

### 5.5 Maintainability

**NFR-501** The backend shall follow a layered architecture: handlers → services → repositories, with no business logic in handler functions.

**NFR-502** Environment-specific configuration (API keys, database URIs, ports) shall be externalized to `.env` files and never hardcoded.

**NFR-503** The codebase shall use linting (ESLint for web, `go vet`/`golint` for backend) enforced in CI.

**NFR-504** CI/CD pipelines shall run on every pull request to `main` and block merges on build or lint failure.

### 5.6 Scalability

**NFR-601** The backend architecture shall allow horizontal scaling by running multiple API server instances behind a load balancer; no in-memory session state shall be required.

**NFR-602** The PostgreSQL `arrivals` table shall be indexed on `(stop_id, route_id, recorded_at)` to support efficient time-range queries at scale.

---

## 6. External Interface Requirements

### 6.1 User Interfaces

**Web App:** Single-page application built in Vue 3. Primary layout consists of a full-screen interactive map with collapsible sidebars for arrival boards, trip planning, and chat. Navigation is via a top header bar with links to Home, Score, About, Account.

**Mobile App:** Flutter native app with a bottom navigation bar (Home, Chat, Scores, Account). The home screen occupies the full screen with the Google Map as the background layer and overlaid UI panels.

### 6.2 Hardware Interfaces

The mobile app requires device GPS hardware for location-based features (FR-1402). No other special hardware interfaces are required.

### 6.3 Software / API Interfaces

| External System | Purpose | Protocol |
|----------------|---------|----------|
| Sound Transit GTFS-RT Vehicle Positions | Live bus locations | HTTP (protobuf) |
| Sound Transit GTFS-RT Trip Updates | Real-time arrival predictions | HTTP (protobuf) |
| Sound Transit GTFS-RT Service Alerts | Active service disruptions | HTTP (protobuf) |
| King County Metro GTFS-RT Service Alerts | Active service disruptions | HTTP (protobuf) |
| OneBusAway REST API | Stop arrivals, stop lookup | HTTPS / JSON |
| Google Maps Platform (Directions API) | Trip route planning | HTTPS / JSON |
| Google Maps Platform (Maps JS / Flutter SDK) | Interactive map tiles | SDK |
| Google Maps Platform (Geocoding / Places) | Address autocomplete | HTTPS / JSON |
| Anthropic Claude API | AI chatbot responses | HTTPS / JSON |
| NOAA Weather API | Current weather and forecast | HTTPS / JSON |
| OpenWeatherMap API | Fallback weather data | HTTPS / JSON |

### 6.4 Communication Interfaces

All client-server communication uses HTTPS REST. The backend API uses JSON for request and response bodies. GTFS-Realtime feeds are fetched by the backend using HTTP GET with protobuf decoding. The transit poller communicates with PostgreSQL over a standard TCP connection using the `psycopg2` driver.

---

## 7. System Architecture

### 7.1 Component Overview

```
├── api/                   Go REST API
│   ├── cmd/               Server entry point
│   └── internal/
│       ├── config/        Environment-based configuration
│       ├── handlers/      HTTP request handlers (thin layer)
│       ├── middleware/     JWT auth, CORS, request logging
│       ├── models/        Data structures (User, Vehicle, Report, etc.)
│       ├── repository/    MongoDB CRUD operations
│       ├── router/        Chi router with route registration
│       ├── server/        Server lifecycle management
│       └── services/      Business logic (transit, reliability, weather, auth, chat)
├── mobile/                Flutter mobile app
│   └── lib/
│       ├── providers/     Riverpod state providers
│       ├── screens/       Page-level widgets
│       ├── services/      HTTP client, geocoding, reliability, chat
│       └── widgets/       Reusable UI components
├── web/                   Vue 3 + TypeScript web app
│   └── src/
│       ├── components/    UI components (map, transit, user, weather, common)
│       ├── router/        Vue Router configuration
│       ├── services/      Axios-based API clients
│       ├── stores/        Pinia state stores
│       ├── types/         TypeScript type definitions
│       └── views/         Page-level Vue components
├── transit-poller/        Python OBA polling service
│   ├── poller.py          60-second polling loop
│   └── stops.py           Monitored stop configuration
└── database/              DB initialization scripts
```

### 7.2 Data Flow: Live Map

```
Sound Transit GTFS-RT Feed
        │  (every 15s, triggered by client poll)
        ▼
  Go transitService.GetVehicles()
        │
        ▼
  JSON vehicle array
        │
        ▼
  Web: mapStore (Pinia)  →  VehicleMarker components on Google Map
  Mobile: provider       →  Flutter Google Maps markers
```

### 7.3 Data Flow: Reliability Score

```
OBA API (real-time arrivals)
        │  (every 60s)
        ▼
  Python transit-poller
        │  INSERT delay_seconds per arrival
        ▼
  PostgreSQL arrivals table
        │  (on-demand query)
        ▼
  Go reliability_service.GetStopReliability()
  (weighted formula, time-bin filter, 90-day window)
        │
        ▼
  JSON score response → ReliabilityBadge / ScoreView
```

### 7.4 API Endpoint Summary

**Public Endpoints (no auth required)**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/transit/vehicles` | Live bus vehicle positions |
| GET | `/api/v1/transit/stops/nearby` | Stops near a lat/lng |
| GET | `/api/v1/transit/stops/:id/arrivals` | Arrivals for a stop |
| GET | `/api/v1/reliability/summary` | Overall reliability summary |
| GET | `/api/v1/reliability/stop/:stopId` | Reliability for a stop |
| GET | `/api/v1/reliability/stop/:stopId/route/:routeId` | Reliability for route at stop |
| GET | `/api/v1/reliability/predict` | Next arrival prediction |
| GET | `/api/v1/routes/plan` | Trip planning (origin → destination) |
| GET | `/api/v1/routes/:id/shape` | Route polyline |
| GET | `/api/v1/routes/:id` | Route metadata |
| GET | `/api/v1/weather` | Current weather at lat/lng |
| GET | `/api/v1/weather/hourly` | Hourly forecast at lat/lng |
| GET | `/api/v1/service-alerts` | Active service alerts |
| GET | `/api/v1/crowdsource/:stopId` | Crowdsource summary for stop |
| GET | `/api/v1/team` | Team member profiles |
| POST | `/api/v1/auth/register` | Create account |
| POST | `/api/v1/auth/login` | Authenticate and receive JWT |
| POST | `/api/v1/chat` | AI chatbot message |

**Protected Endpoints (JWT required)**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users/me` | Get current user profile |
| PUT | `/api/v1/users/me/settings` | Update user settings |
| DELETE | `/api/v1/users/me` | Delete account |
| GET | `/api/v1/users/me/favorites` | List saved favorite routes |
| POST | `/api/v1/users/me/favorites` | Add favorite route |
| DELETE | `/api/v1/users/me/favorites/:id` | Remove favorite route |
| POST | `/api/v1/reports` | Submit general condition report |
| GET | `/api/v1/reports/mine` | List own reports |
| POST | `/api/v1/vehicle-reports/cleanliness` | Submit cleanliness report |
| POST | `/api/v1/vehicle-reports/crowding` | Submit crowding report |
| POST | `/api/v1/vehicle-reports/delay` | Submit delay report |
| GET | `/api/v1/vehicle-reports/mine` | List own vehicle reports |
| DELETE | `/api/v1/vehicle-reports/:id` | Delete own report |
| GET | `/api/v1/notifications` | List notifications |
| PATCH | `/api/v1/notifications/:id/read` | Mark notification read |
| PATCH | `/api/v1/notifications/read-all` | Mark all notifications read |

---

## 8. Data Requirements

### 8.1 PostgreSQL Schema

**Table: `arrivals`**

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-increment row ID |
| `stop_id` | VARCHAR | OBA stop identifier |
| `route_id` | VARCHAR | Transit route identifier |
| `trip_id` | VARCHAR | GTFS trip identifier |
| `headsign` | VARCHAR | Route destination text |
| `scheduled_arrival_ms` | BIGINT | Scheduled arrival (epoch ms) |
| `predicted_arrival_ms` | BIGINT | Predicted arrival (epoch ms) |
| `delay_seconds` | FLOAT | `(predicted - scheduled) / 1000` |
| `recorded_at` | TIMESTAMP | When this record was inserted |

Index: `(stop_id, route_id, recorded_at)` for reliability query performance.

### 8.2 MongoDB Collections

**Collection: `users`**

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectID | MongoDB document ID |
| `email` | String | Unique user email |
| `passwordHash` | String | bcrypt hash |
| `displayName` | String | User display name |
| `notificationsEnabled` | Boolean | Notification preference |
| `tempUnit` | String | "F" or "C" |
| `distanceUnit` | String | "miles" or "km" |
| `deleted` | Boolean | Soft-delete flag |
| `createdAt`, `updatedAt` | Date | Timestamps |

**Collection: `favorite_routes`**

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectID | Document ID |
| `userID` | ObjectID | Reference to user |
| `label` | String | User-defined label |
| `origin` | Object | Place reference (name, lat, lng) |
| `destination` | Object | Place reference (name, lat, lng) |
| `transitRouteIds` | Array[String] | Associated route IDs |

**Collection: `vehicle_reports`**

Stores cleanliness, crowding, and delay reports with `userID`, `routeId`, `vehicleId`, `level` (1–5), `type`, and `createdAt`.

**Collection: `reports`**

Stores general condition reports with `userID`, `routeId`, `vehicleId`, `type`, `severity`, `description`, `location`, and `createdAt`.

**Collection: `notifications`**

| Field | Type | Description |
|-------|------|-------------|
| `userID` | ObjectID | Recipient user |
| `routeID` | String | Related route |
| `reportType` | String | Type of triggering report |
| `message` | String | Notification body |
| `read` | Boolean | Read status |
| `createdAt` | Date | Timestamp |

---

## 9. Constraints and Assumptions

### 9.1 Constraints

- **Google Maps API key:** All map display, geocoding, and directions features require a valid Google Maps API key with the Maps JS API, Maps Flutter SDK, Directions API, Geocoding API, and Places API enabled.
- **Anthropic API key:** The AI chatbot requires an active Anthropic API key with access to the `claude-haiku-4-5-20251001` model.
- **OBA API key:** Transit arrival and stop data requires an active OneBusAway API key.
- **GTFS-Realtime feeds:** Real-time vehicle positions depend on Sound Transit's public GTFS-RT feed URL remaining available and in the standard protobuf format.
- **Geographic scope:** The transit poller is currently configured to poll 4 stops in the Bellevue area. Expanding coverage requires adding stop IDs to `transit-poller/stops.py` and sufficient PostgreSQL storage for additional arrival history.
- **Cost:** Reliability and AI features incur direct API costs. This system is scoped for academic/demo usage and has not been designed for high-volume production traffic without budget planning.

### 9.2 Assumptions

- Users have a stable internet connection for real-time features.
- Sound Transit and King County Metro will continue publishing GTFS-RT feeds in the current format.
- The OBA API is available and reflects accurate data for the covered service area.
- The deployment environment (AWS Amplify) will remain the hosting target for the academic term.
- Browser-based users on mobile will access the web app via a modern mobile browser; the native Flutter app is the preferred mobile experience.
- The academic demo period does not require the system to handle more than ~100 concurrent users.

---

*End of Software Requirements Specification*
