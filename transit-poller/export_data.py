import psycopg2
import json
import csv
import os
import argparse
from datetime import datetime, timedelta
from dotenv import load_dotenv
from zoneinfo import ZoneInfo

load_dotenv()

AGENCY_MAP = {
    "1_": "King County Metro",
    "3_": "Sound Transit",
    "29_": "Community Transit",
    "40_": "Sound Transit Link Light Rail",
}

TZ_LA = ZoneInfo("America/Los_Angeles")

def get_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

def get_agency(route_id):
    """Infer agency from route_id prefix."""
    for prefix, agency in AGENCY_MAP.items():
        if route_id.startswith(prefix):
            return agency
    return "Unknown"

def get_time_bin(timestamp_ms):
    """Get time bin (morning, midday, afternoon, evening) from epoch ms."""
    dt = datetime.fromtimestamp(timestamp_ms / 1000, tz=TZ_LA)
    hour = dt.hour
    if 6 <= hour < 9:
        return "morning"
    elif 9 <= hour < 15:
        return "midday"
    elif 15 <= hour < 19:
        return "afternoon"
    else:
        return "evening"

def is_on_time(delay_seconds):
    """On-time if |delay| <= 120 seconds."""
    return abs(delay_seconds) <= 120

def fetch_arrivals(conn, date):
    """Fetch all arrivals for a given date (YYYY-MM-DD)."""
    cur = conn.cursor()

    # Query for all arrivals on that calendar day (LA timezone)
    query = """
        SELECT id, stop_id, route_id, trip_id, headsign,
               scheduled_arrival, predicted_arrival, delay_seconds, recorded_at
        FROM arrivals
        WHERE DATE(recorded_at AT TIME ZONE 'America/Los_Angeles') = %s
        ORDER BY recorded_at ASC
    """
    cur.execute(query, (date,))
    rows = cur.fetchall()
    cur.close()
    return rows

def export_raw(conn, date, out_dir):
    """Export raw arrivals to JSON and CSV."""
    rows = fetch_arrivals(conn, date)

    os.makedirs(out_dir, exist_ok=True)

    # JSON export
    records = []
    for row in rows:
        records.append({
            "id": row[0],
            "stop_id": row[1],
            "route_id": row[2],
            "trip_id": row[3],
            "headsign": row[4],
            "scheduled_arrival": row[5],
            "predicted_arrival": row[6],
            "delay_seconds": row[7],
            "recorded_at": row[8].isoformat(),
        })

    json_path = os.path.join(out_dir, "raw.json")
    with open(json_path, "w") as f:
        json.dump(records, f, indent=2, default=str)
    print(f"✓ Exported {len(records)} records to {json_path}")

    # CSV export
    csv_path = os.path.join(out_dir, "raw.csv")
    if records:
        with open(csv_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=records[0].keys())
            writer.writeheader()
            writer.writerows(records)
        print(f"✓ Exported {len(records)} records to {csv_path}")

    return records

def export_rag(conn, date, out_dir, records=None):
    """Export RAG-ready summaries."""
    if records is None:
        rows = fetch_arrivals(conn, date)
        records = [
            {
                "stop_id": row[1],
                "route_id": row[2],
                "headsign": row[4],
                "scheduled_arrival": row[5],
                "predicted_arrival": row[6],
                "delay_seconds": row[7],
            }
            for row in rows
        ]

    # Aggregate by route
    route_data = {}
    for rec in records:
        route_id = rec["route_id"]
        if route_id not in route_data:
            route_data[route_id] = []
        route_data[route_id].append(rec)

    # Aggregate by stop
    stop_data = {}
    for rec in records:
        stop_id = rec["stop_id"]
        if stop_id not in stop_data:
            stop_data[stop_id] = []
        stop_data[stop_id].append(rec)

    # Aggregate by (route, time_bin)
    route_timebin_data = {}
    for rec in records:
        route_id = rec["route_id"]
        time_bin = get_time_bin(rec["scheduled_arrival"])
        key = (route_id, time_bin)
        if key not in route_timebin_data:
            route_timebin_data[key] = []
        route_timebin_data[key].append(rec)

    rag_docs = []

    # Route summaries
    for route_id, arrivals in route_data.items():
        if not arrivals:
            continue

        total = len(arrivals)
        on_time_count = sum(1 for a in arrivals if is_on_time(a["delay_seconds"]))
        early_count = sum(1 for a in arrivals if a["delay_seconds"] < -120)
        late_count = sum(1 for a in arrivals if a["delay_seconds"] > 120)

        avg_delay = sum(a["delay_seconds"] for a in arrivals) / total
        on_time_rate = on_time_count / total
        pct_early = early_count / total
        pct_late = late_count / total

        headsign = arrivals[0]["headsign"] or "Unknown"
        agency = get_agency(route_id)

        doc = {
            "type": "route_summary",
            "date": str(date),
            "route_id": route_id,
            "headsign": headsign,
            "agency": agency,
            "total_records": total,
            "avg_delay_seconds": round(avg_delay, 2),
            "on_time_rate": round(on_time_rate, 3),
            "pct_early": round(pct_early, 3),
            "pct_late": round(pct_late, 3),
            "text": (
                f"On {date}, Route {route_id} ({headsign}, {agency}) recorded {total} arrivals. "
                f"Average delay was {abs(round(avg_delay))} seconds {'late' if avg_delay > 0 else 'early'}. "
                f"On-time rate: {round(on_time_rate * 100)}%. {round(pct_early * 100)}% early, {round(pct_late * 100)}% late."
            )
        }
        rag_docs.append(doc)

    # Stop summaries
    for stop_id, arrivals in stop_data.items():
        if not arrivals:
            continue

        total = len(arrivals)
        on_time_count = sum(1 for a in arrivals if is_on_time(a["delay_seconds"]))
        avg_delay = sum(a["delay_seconds"] for a in arrivals) / total
        on_time_rate = on_time_count / total

        routes = sorted(set(a["route_id"] for a in arrivals))

        doc = {
            "type": "stop_summary",
            "date": str(date),
            "stop_id": stop_id,
            "total_records": total,
            "routes_served": routes,
            "avg_delay_seconds": round(avg_delay, 2),
            "on_time_rate": round(on_time_rate, 3),
            "text": (
                f"On {date}, stop {stop_id} recorded {total} arrivals across {len(routes)} routes. "
                f"Average delay: {round(abs(avg_delay))} seconds. On-time rate: {round(on_time_rate * 100)}%."
            )
        }
        rag_docs.append(doc)

    # Time-of-day summaries
    for (route_id, time_bin), arrivals in route_timebin_data.items():
        if not arrivals:
            continue

        total = len(arrivals)
        on_time_count = sum(1 for a in arrivals if is_on_time(a["delay_seconds"]))
        avg_delay = sum(a["delay_seconds"] for a in arrivals) / total
        on_time_rate = on_time_count / total

        time_range = {
            "morning": "6–9 AM",
            "midday": "9 AM–3 PM",
            "afternoon": "3–7 PM",
            "evening": "7 PM+",
        }[time_bin]

        doc = {
            "type": "time_bin_summary",
            "date": str(date),
            "route_id": route_id,
            "time_bin": time_bin,
            "total_records": total,
            "avg_delay_seconds": round(avg_delay, 2),
            "on_time_rate": round(on_time_rate, 3),
            "text": (
                f"On {date} during {time_bin} hours ({time_range}), Route {route_id} recorded {total} arrivals "
                f"with an average delay of {round(abs(avg_delay))} seconds and a {round(on_time_rate * 100)}% on-time rate."
            )
        }
        rag_docs.append(doc)

    os.makedirs(out_dir, exist_ok=True)
    rag_path = os.path.join(out_dir, f"rag_dataset_{date}.json")
    with open(rag_path, "w") as f:
        json.dump(rag_docs, f, indent=2)

    print(f"✓ Exported {len(rag_docs)} RAG documents to {rag_path}")
    return rag_docs

def main():
    parser = argparse.ArgumentParser(description="Export transit arrivals data for RAG")
    parser.add_argument(
        "--date",
        type=str,
        default=None,
        help="Date to export (YYYY-MM-DD). Defaults to yesterday."
    )
    args = parser.parse_args()

    if args.date:
        target_date = args.date
    else:
        # Default to yesterday
        target_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

    print(f"Exporting data for {target_date}...\n")

    conn = get_db()
    out_dir = os.path.join("data", target_date)

    # Export raw and RAG together (reuse records for efficiency)
    records = export_raw(conn, target_date, out_dir)
    export_rag(conn, target_date, out_dir, records=records)

    conn.close()
    print(f"\n✓ Export complete: {out_dir}/")

if __name__ == "__main__":
    main()
