import requests
import psycopg2
import time
import os
import json
from dotenv import load_dotenv
from datetime import datetime
from stops import BELLEVUE_STOPS

load_dotenv()

API_KEY = os.getenv("OBA_API_KEY")
BASE_URL = "https://api.pugetsound.onebusaway.org/api/where"

ST_ALERTS_URL = "https://s3.amazonaws.com/st-service-alerts-prod/alerts_pb.json"
KCM_ALERTS_URL = "https://s3.amazonaws.com/kcm-alerts-realtime-prod/alerts_enhanced.json"

def get_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

def init_db():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS arrivals (
            id SERIAL PRIMARY KEY,
            stop_id TEXT,
            route_id TEXT,
            trip_id TEXT,
            headsign TEXT,
            scheduled_arrival BIGINT,
            predicted_arrival BIGINT,
            delay_seconds INTEGER,
            recorded_at TIMESTAMP DEFAULT NOW()
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS service_alerts (
            id SERIAL PRIMARY KEY,
            alert_id TEXT NOT NULL,
            agency TEXT NOT NULL,
            effect TEXT,
            cause TEXT,
            header_text TEXT,
            description_text TEXT,
            severity_level TEXT,
            active_period_start BIGINT,
            active_period_end BIGINT,
            informed_entity TEXT,
            url TEXT,
            last_seen TIMESTAMP DEFAULT NOW(),
            UNIQUE(alert_id, agency)
        )
    """)
    conn.commit()
    cur.close()
    conn.close()
    print("Database initialized.")

def fetch_service_alerts(url):
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            print(f"Error fetching alerts from {url}: {response.status_code}")
            return []
        return response.json().get("entity", [])
    except Exception as e:
        print(f"Exception fetching alerts from {url}: {e}")
        return []

def store_service_alerts(agency, entities):
    conn = get_db()
    cur = conn.cursor()
    count = 0
    for entity in entities:
        alert_id = entity.get("id")
        alert = entity.get("alert", {})

        effect = alert.get("effect")
        cause = alert.get("cause")
        severity_level = alert.get("severity_level")

        header_text = next(
            (t.get("text") for t in alert.get("header_text", {}).get("translation", []) if t.get("language") == "en"),
            None
        )
        description_text = next(
            (t.get("text") for t in alert.get("description_text", {}).get("translation", []) if t.get("language") == "en"),
            None
        )
        url = next(
            (t.get("text") for t in alert.get("url", {}).get("translation", []) if t.get("language") == "en"),
            None
        )

        active_periods = alert.get("active_period", [])
        active_start = active_periods[0].get("start") if active_periods else None
        active_end = active_periods[0].get("end") if active_periods else None

        informed_entity = json.dumps(alert.get("informed_entity", []))

        cur.execute("""
            INSERT INTO service_alerts
                (alert_id, agency, effect, cause, header_text, description_text,
                 severity_level, active_period_start, active_period_end, informed_entity, url, last_seen)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            ON CONFLICT (alert_id, agency) DO UPDATE SET
                effect = EXCLUDED.effect,
                cause = EXCLUDED.cause,
                header_text = EXCLUDED.header_text,
                description_text = EXCLUDED.description_text,
                severity_level = EXCLUDED.severity_level,
                active_period_start = EXCLUDED.active_period_start,
                active_period_end = EXCLUDED.active_period_end,
                informed_entity = EXCLUDED.informed_entity,
                url = EXCLUDED.url,
                last_seen = NOW()
        """, (
            alert_id, agency, effect, cause, header_text, description_text,
            severity_level, active_start, active_end, informed_entity, url
        ))
        count += 1

    conn.commit()
    cur.close()
    conn.close()
    return count

def fetch_arrivals(stop_id):
    url = f"{BASE_URL}/arrivals-and-departures-for-stop/{stop_id}.json"
    params = {"key": API_KEY, "minutesAfter": 60}
    try:
        response = requests.get(url, params=params, timeout=10)
        if response.status_code != 200:
            return []
        data = response.json()
        return data.get("data", {}).get("entry", {}).get("arrivalsAndDepartures", [])
    except requests.RequestException:
        return []

def store_arrivals(conn, stop_id, arrivals):
    cur = conn.cursor()
    count = 0
    for a in arrivals:
        scheduled = a.get("scheduledArrivalTime")
        predicted = a.get("predictedArrivalTime")

        # Only store if we have both scheduled and a real prediction
        if not scheduled or not predicted or predicted == 0:
            continue

        delay_seconds = (predicted - scheduled) // 1000  # convert ms to seconds

        cur.execute("""
            INSERT INTO arrivals
                (stop_id, route_id, trip_id, headsign, scheduled_arrival, predicted_arrival, delay_seconds)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            stop_id,
            a.get("routeId"),
            a.get("tripId"),
            a.get("tripHeadsign"),
            scheduled,
            predicted,
            delay_seconds
        ))
        count += 1

    conn.commit()
    cur.close()
    return count

def run():
    init_db()
    print(f"Starting poller. Checking {len(BELLEVUE_STOPS)} stops every 60 seconds...\n")
    while True:
        try:
            timestamp = datetime.now().strftime("%H:%M:%S")

            try:
                st_entities = fetch_service_alerts(ST_ALERTS_URL)
                st_count = store_service_alerts("sound_transit", st_entities)
                print(f"[{timestamp}] Sound Transit alerts: {len(st_entities)} fetched, {st_count} upserted")

                kcm_entities = fetch_service_alerts(KCM_ALERTS_URL)
                kcm_count = store_service_alerts("king_county_metro", kcm_entities)
                print(f"[{timestamp}] King County Metro alerts: {len(kcm_entities)} fetched, {kcm_count} upserted")
            except Exception as e:
                print(f"[{timestamp}] ERROR fetching service alerts: {e}")

            try:
                conn = get_db()
            except Exception as e:
                print(f"[{timestamp}] DB connection failed: {e}. Retrying next cycle.")
                time.sleep(60)
                continue

            total = 0
            for stop_id in BELLEVUE_STOPS:
                try:
                    arrivals = fetch_arrivals(stop_id)
                    saved = store_arrivals(conn, stop_id, arrivals)
                    total += saved
                    print(f"[{timestamp}] Stop {stop_id}: {len(arrivals)} arrivals fetched, {saved} with predictions stored")
                except Exception as e:
                    print(f"[{timestamp}] ERROR on stop {stop_id}: {e}")

            try:
                conn.close()
            except Exception:
                pass

            print(f"  → Total stored this cycle: {total}\n")
            time.sleep(60)

        except Exception as e:
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] FATAL: Unexpected error in cycle: {e}")
            print(f"[{timestamp}] Restarting in 60 seconds...")
            time.sleep(60)

if __name__ == "__main__":
    run()