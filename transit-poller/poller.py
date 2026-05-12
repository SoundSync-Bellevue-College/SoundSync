import requests
import psycopg2
import time
import os
from dotenv import load_dotenv
from datetime import datetime
from stops import BELLEVUE_STOPS

load_dotenv()

API_KEY = os.getenv("OBA_API_KEY")
BASE_URL = "https://api.pugetsound.onebusaway.org/api/where"

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
    conn.commit()
    cur.close()
    conn.close()
    print("Database initialized.")

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