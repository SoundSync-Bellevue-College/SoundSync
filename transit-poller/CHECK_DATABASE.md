# How to Check the PostgreSQL Database for Recent Data

This tutorial shows you how to query the `soundsync` PostgreSQL database to verify that the poller is collecting transit arrival data.

## Prerequisites

- PostgreSQL is running (you can verify with `ps aux | grep postgres`)
- The poller has been run at least once (it creates the `arrivals` table)
- Python 3 with `psycopg2` installed (available in `/home/nngo/.venv`)

## Quick Check: Using Python

This is the easiest method. Run from the `/home/nngo/SoundSync/transit-poller/` directory:

```bash
python3 << 'EOF'
import psycopg2

# Connect to PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    port="5432",
    dbname="soundsync",
    user="postgres",
    password="postgres"
)
cur = conn.cursor()

# Get total records and latest timestamp
cur.execute("SELECT COUNT(*) as total FROM arrivals;")
total = cur.fetchone()[0]

cur.execute("SELECT MAX(recorded_at) as latest FROM arrivals;")
latest = cur.fetchone()[0]

print(f"Total records: {total}")
print(f"Latest data: {latest}")

cur.close()
conn.close()
EOF
```

## View Recent Arrivals

To see the last 10 arrivals stored in the database:

```bash
python3 << 'EOF'
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    dbname="soundsync",
    user="postgres",
    password="postgres"
)
cur = conn.cursor()

# Get last 10 arrivals
cur.execute("""
    SELECT stop_id, route_id, headsign, delay_seconds, recorded_at 
    FROM arrivals 
    ORDER BY recorded_at DESC 
    LIMIT 10;
""")

print("Recent arrivals:")
print("Stop ID | Route ID | Headsign | Delay (sec) | Recorded At")
print("-" * 80)
for row in cur.fetchall():
    print(f"{row[0]:<12} | {row[1]:<15} | {row[2]:<40} | {row[3]:>6} | {row[4]}")

cur.close()
conn.close()
EOF
```

## Check Data by Stop

To see arrivals for a specific stop (e.g., stop `1_67652`):

```bash
python3 << 'EOF'
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    dbname="soundsync",
    user="postgres",
    password="postgres"
)
cur = conn.cursor()

stop_id = "1_67652"  # Change this to any stop ID

cur.execute("""
    SELECT route_id, headsign, COUNT(*) as count, 
           AVG(delay_seconds) as avg_delay, 
           MAX(recorded_at) as latest
    FROM arrivals 
    WHERE stop_id = %s
    GROUP BY route_id, headsign
    ORDER BY latest DESC;
""", (stop_id,))

print(f"Arrivals for stop {stop_id}:")
print("Route ID | Headsign | Count | Avg Delay | Latest Time")
print("-" * 80)
for row in cur.fetchall():
    print(f"{row[0]:<12} | {row[1]:<40} | {row[2]:>5} | {row[3]:>6.0f}s | {row[4]}")

cur.close()
conn.close()
EOF
```

## Check Data Freshness

To confirm the poller is actively collecting data:

```bash
python3 << 'EOF'
import psycopg2
from datetime import datetime, timedelta

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    dbname="soundsync",
    user="postgres",
    password="postgres"
)
cur = conn.cursor()

# Get records from the last 5 minutes
five_min_ago = datetime.now() - timedelta(minutes=5)

cur.execute("""
    SELECT COUNT(*) 
    FROM arrivals 
    WHERE recorded_at > %s;
""", (five_min_ago,))

recent_count = cur.fetchone()[0]
print(f"Records from last 5 minutes: {recent_count}")

if recent_count > 0:
    print("✓ Poller is actively collecting data!")
else:
    print("✗ No new data in last 5 minutes. Poller may not be running.")

cur.close()
conn.close()
EOF
```

## Database Schema

The `arrivals` table has these columns:

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL | Primary key (auto-increment) |
| `stop_id` | TEXT | Bus stop ID |
| `route_id` | TEXT | Bus route ID |
| `trip_id` | TEXT | Trip ID |
| `headsign` | TEXT | Route destination (e.g., "Downtown Seattle") |
| `scheduled_arrival` | BIGINT | Scheduled arrival time (milliseconds since epoch) |
| `predicted_arrival` | BIGINT | Predicted arrival time (milliseconds since epoch) |
| `delay_seconds` | INTEGER | Difference in seconds (predicted - scheduled) |
| `recorded_at` | TIMESTAMP | When this record was inserted (default: NOW()) |

## Connection Details

If you need to connect directly using other tools:

```
Host: localhost
Port: 5432
Database: soundsync
Username: postgres
Password: postgres
```

## Troubleshooting

**"Connection refused"**
- Check if PostgreSQL is running: `ps aux | grep postgres`
- PostgreSQL may need to be started (check docker-compose or systemd)

**"relation 'arrivals' does not exist"**
- The poller hasn't been run yet
- Run the poller once: `python3 poller.py` (let it run for a moment, then Ctrl+C)

**"Authentication failed for user 'postgres'"**
- Check the `.env` file in the transit-poller directory
- Verify the password matches your PostgreSQL setup
