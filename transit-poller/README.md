# Transit Poller

A Python service that polls the [OneBusAway Puget Sound API](https://api.pugetsound.onebusaway.org) every 60 seconds and stores real-time arrival data for a set of stops into a PostgreSQL `arrivals` table. This data feeds the SoundSync prediction model.

## How it works

`poller.py` queries each configured stop, computes the delay between the scheduled and predicted arrival times, and inserts a row into the database:

```
delay_seconds = (predictedArrivalTime - scheduledArrivalTime) / 1000
```

Both timestamps come from the OBA API in milliseconds. Only arrivals that carry a live prediction (`predictedArrivalTime != 0`) are stored.

---

## Prediction Model Formulas

The Go backend (`backend/internal/predictions/service.go`) consumes historical report data from MongoDB to produce forecasts for a given route, stop, direction, and time window.

### Time binning

Before computing statistics, reports are grouped by **time-of-day bin** and **day type** so that, for example, a morning weekday query is only compared against other morning weekday observations.

| Bin | Hours (local UTC) |
|---|---|
| `morning` | 06:00 – 08:59 |
| `midday` | 09:00 – 14:59 |
| `afternoon` | 15:00 – 17:59 |
| `evening` | 18:00 – 20:59 |
| `night` | 21:00 – 05:59 |

Day types: `weekday` (Mon–Fri) and `weekend` (Sat–Sun).

Only reports from the **last 90 days** are used.

---

### Predicted value (mean delay / crowding level)

The core prediction is the arithmetic mean of all matching historical values:

```
predicted = round( Σ values / n , 2 )
```

Where `n` is the number of matching reports (sample size). Rounding is to 2 decimal places.

---

### 90th-percentile (worst-case estimate)

Used to give riders a sense of the upper bound they might experience:

```
idx   = ceil( 90/100 × n ) − 1
p90   = sorted_values[idx]
```

This is the nearest-rank method. The result is also rounded to 2 decimal places.

---

### Confidence score

Expresses how much weight to place on the prediction based on the number of data points. Ranges from 0 (no data) to just below 1 (very large sample):

```
confidence = 1 − e^(−n / 10)
```

The divisor `10` is the scaling factor. Representative values:

| Sample size (n) | Confidence |
|---|---|
| 0 | 0.00 |
| 3 | 0.26 |
| 5 | 0.39 |
| 10 | 0.63 |
| 20 | 0.86 |
| 30 | 0.95 |

Confidence never reaches exactly 1.0, reflecting that any prediction carries residual uncertainty.

---

## API Endpoints

Endpoints are URLs the Go backend exposes so that clients (the Flutter app, Postman, etc.) can send HTTP requests to fetch or submit data. Each endpoint has a method (`GET` to read, `POST` to create), a path, and returns a JSON response.

All endpoints below require a `Bearer <token>` header obtained from `/api/v1/auth/login`, except where noted.

---

### Authentication

#### `POST /api/v1/auth/signup`
Creates a new user account. No auth token required.

**Body:**
```json
{ "username": "string", "name": "string", "email": "string", "password": "string" }
```

#### `POST /api/v1/auth/login`
Authenticates a user and returns a JWT token used to authorize all other requests.

**Body:**
```json
{ "username": "string", "password": "string" }
```

**Response:** `{ "token": "..." }`

#### `POST /api/v1/auth/logout`
Invalidates the current token so it can no longer be used.

---

### Notifications

#### `GET /api/v1/notifications`
Returns the authenticated user's notification preferences and their list of subscribed routes.

#### `PUT /api/v1/notifications/preferences`
Enables or disables push notifications for the authenticated user.

**Body:** `{ "enabled": true }`

#### `POST /api/v1/notifications/subscriptions`
Subscribes the authenticated user to delay alerts for a route.

**Body:** `{ "routeId": "string" }`

#### `DELETE /api/v1/notifications/subscriptions/{routeId}`
Removes the authenticated user's subscription for the given route.

---

### Reports

Users submit reports from the app. Reports are stored in MongoDB and used as the training data for the prediction model.

#### `POST /api/v1/delay-reports`
Submits a delay observation for a route/stop.

**Body:**
```json
{
  "routeId": "string",
  "stopId": "string",
  "directionId": 0,
  "vehicle_id": "string",
  "report_time": "2026-03-04T08:00:00Z",
  "delay_minutes": 3
}
```

#### `GET /api/v1/delay-reports`
Returns a list of delay reports. Results are sorted newest-first, capped at 200.

**Query params:** `routeId`, `stopId`, `directionId`, `limit`

#### `POST /api/v1/crowding-reports`
Submits a crowding observation (scale 1–5) for a route/stop.

**Body:** same shape as delay report but with `"crowding_level": 1-5` instead of `delay_minutes`.

#### `GET /api/v1/crowding-reports`
Returns crowding reports. Same query params as delay reports.

#### `POST /api/v1/cleanliness-reports`
Submits a cleanliness observation (scale 1–5) for a route/stop.

**Body:** same shape but with `"cleanliness_level": 1-5`.

#### `GET /api/v1/cleanliness-reports`
Returns cleanliness reports. Same query params as delay reports.

---

### Predictions

These endpoints analyze the last 90 days of submitted reports for a given route/stop, filter to the matching time-of-day bin and day type, and return a statistical forecast. See the **Prediction Model Formulas** section for how the numbers are computed.

#### `GET /api/v1/predictions/delay`
Returns a predicted delay in minutes for a route/stop at a given time.

**Query params:**

| Param | Required | Description |
|---|---|---|
| `routeId` | yes | The route to predict for (e.g. `100001`) |
| `stopId` | no | Narrows prediction to a specific stop |
| `directionId` | no | `0` or `1` |
| `at` | no | RFC3339 timestamp to predict for (defaults to now) |

**Example:** `GET /api/v1/predictions/delay?routeId=100001&stopId=100&at=2026-03-04T08:30:00Z`

**Response:**
```json
{
  "prediction": {
    "routeId": "100001",
    "stopId": "100",
    "directionId": 0,
    "predicted_delay_minutes": 3.5,
    "percentile_90_delay_minutes": 6.0,
    "confidence": 0.63,
    "sample_size": 10,
    "time_bin": "morning",
    "day_type": "weekday"
  }
}
```

#### `GET /api/v1/predictions/crowding`
Returns a predicted crowding level (1–5 scale) for a route/stop at a given time. Accepts the same query params as the delay prediction endpoint.

**Response shape:** same as above but with `predicted_crowding_level` and `percentile_90_crowding_level` instead of the delay fields.

---

### Health Check

#### `GET /health`
Returns `{ "status": "ok" }` if the server is running. No auth required. Useful for uptime monitoring.

---

## Setup

Copy `.env.example` to `.env` and fill in your credentials:

```
OBA_API_KEY=your_key_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=soundsync
DB_USER=postgres
DB_PASSWORD=yourpassword
```

Install dependencies and run:

```bash
pip install requests psycopg2-binary python-dotenv
python poller.py
```
