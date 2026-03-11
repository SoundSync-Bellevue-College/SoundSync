# SoundSync Demo Guide

## Prerequisites

- Docker + Docker Compose
- Go 1.22+
- Node.js 18+
- Python 3.8+ (optional — for live reliability data)
- A Google Maps API key

---

## Step 1 — Fill in your Google Maps key

Open `.env` at the repo root and set your key:

```
GOOGLE_MAPS_API_KEY=your_actual_key_here
```

Everything else works on the defaults. The map won't load without this key.

---

## Step 2 — Start the databases

```bash
cd ~/SoundSync
docker compose up -d
```

This starts three containers:

| Container | What | Port |
|---|---|---|
| `soundsync_postgres` | PostgreSQL (arrivals) | 5432 |
| `soundsync_mongo` | MongoDB (users, reports) | 27017 |
| `soundsync_mongo_express` | Mongo admin UI | 8081 |

Wait ~5 seconds for MongoDB to finish its init script, then verify all three show `running`:

```bash
docker compose ps
```

---

## Step 3 — Start the Go backend

```bash
cd ~/SoundSync/api
go run main.go
```

You should see:

```
Loaded env from ../.env
Connected to MongoDB: soundsync
Connected to PostgreSQL: localhost/soundsync
```

Test it's alive:

```bash
curl http://localhost:8080/health
# {"status":"ok"}
```

---

## Step 4 — Start the Vue web frontend

Open a new terminal:

```bash
cd ~/SoundSync/web
npm install        # first time only
npm run dev
```

Open **http://localhost:5173** in your browser. Vite proxies all `/api` calls to the Go backend on port 8080.

---

## Step 5 (optional) — Run the transit poller for live reliability data

Open a third terminal:

```bash
cd ~/transit-poller
pip install requests psycopg2-binary python-dotenv  # first time only
python poller.py
```

The poller hits the OneBusAway API every 60 seconds and writes arrival data to PostgreSQL. Reliability endpoints return empty data until at least one poll cycle completes. You'll see output like:

```
[12:15:00] Stop 1_67652: 8 arrivals fetched, 6 with predictions stored
```

---

## Quick demo flow

1. Register an account at **http://localhost:5173/register**
2. Log in and explore the map — live Sound Transit vehicles appear
3. Search for a destination and view route options
4. If the poller has run, open an arrival board for stop `1_67652` (Bellevue TC) and the reliability card will show scores, on-time %, and the time-of-day breakdown
5. Verify the reliability API directly:

```bash
curl "http://localhost:8080/api/v1/reliability/summary"
curl "http://localhost:8080/api/v1/reliability/1_67652"
```

---

## Tear down

```bash
# Stop containers, keep data volumes
docker compose down

# Stop and wipe all data (clean slate)
docker compose down -v
```
