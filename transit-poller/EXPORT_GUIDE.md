# Transit Data Export for RAG

This guide explains how to export transit arrivals data from PostgreSQL into formats ready for RAG ingestion.

## Quick Start

```bash
cd /home/nngo/SoundSync/transit-poller

# Export today's data
python3 export_data.py --date 2026-04-22

# Export a specific date
python3 export_data.py --date 2026-04-21

# Export yesterday (default)
python3 export_data.py
```

## Output Structure

Each run creates a directory `data/YYYY-MM-DD/` with three files:

```
data/2026-04-22/
├── raw.json                    (3.2 MB) — Every individual arrival record
├── raw.csv                     (1.3 MB) — Same data in tabular CSV form
└── rag_dataset_2026-04-22.json (100 KB) — Pre-summarized documents for RAG
```

## File Formats

### raw.json / raw.csv

Every arrival record from the database, one row per record:

```json
{
  "id": 301724,
  "stop_id": "1_67652",
  "route_id": "40_100239",
  "trip_id": "40_597752630",
  "headsign": "Seattle",
  "scheduled_arrival": 1776877380000,
  "predicted_arrival": 1776877380000,
  "delay_seconds": 0,
  "recorded_at": "2026-04-22T16:07:23.704058"
}
```

**Use case:** Store the raw data for auditing, offline analysis, or future re-processing.

### rag_dataset.json

Pre-summarized documents ready for a vector store. Each document has a human-readable `text` field.

#### Route Summary
Aggregated metrics per route for the day:

```json
{
  "type": "route_summary",
  "date": "2026-04-22",
  "route_id": "40_100239",
  "headsign": "Seattle",
  "agency": "Sound Transit Link Light Rail",
  "total_records": 518,
  "avg_delay_seconds": 19.65,
  "on_time_rate": 0.867,
  "pct_early": 0.039,
  "pct_late": 0.095,
  "text": "On 2026-04-22, Route 40_100239 (Seattle, Sound Transit Link Light Rail) recorded 518 arrivals. Average delay was 20 seconds late. On-time rate: 87%. 4% early, 9% late."
}
```

#### Stop Summary
Aggregated metrics per stop for the day:

```json
{
  "type": "stop_summary",
  "date": "2026-04-22",
  "stop_id": "1_72984",
  "total_records": 213,
  "routes_served": ["1_100136", "1_100162", "1_102552", "1_102752"],
  "avg_delay_seconds": 31.85,
  "on_time_rate": 0.887,
  "text": "On 2026-04-22, stop 1_72984 recorded 213 arrivals across 4 routes. Average delay: 32 seconds. On-time rate: 89%."
}
```

#### Time-of-Day Summary
Aggregated metrics per route, grouped by time of day:

```json
{
  "type": "time_bin_summary",
  "date": "2026-04-22",
  "route_id": "40_100239",
  "time_bin": "afternoon",
  "total_records": 138,
  "avg_delay_seconds": 187,
  "on_time_rate": 0.52,
  "text": "On 2026-04-22 during afternoon hours (3–7 PM), Route 40_100239 recorded 138 arrivals with an average delay of 187 seconds and a 52% on-time rate."
}
```

**Time bins (America/Los_Angeles timezone):**
- `morning`: 6–9 AM
- `midday`: 9 AM–3 PM
- `afternoon`: 3–7 PM
- `evening`: 7 PM+

## Metrics & Definitions

- **delay_seconds**: `predicted_arrival - scheduled_arrival` (in milliseconds from API, converted to seconds)
  - Positive = late, negative = early
  
- **on_time_rate**: % of arrivals where `|delay_seconds| ≤ 120` (within ±2 minutes)
  
- **avg_delay**: Average delay in seconds (can be positive or negative)
  
- **Agency inference**: Inferred from route_id prefix
  - `1_` → King County Metro
  - `3_` → Sound Transit
  - `29_` → Community Transit
  - `40_` → Sound Transit Link Light Rail

## Using with a Vector Store

Once you have `rag_dataset_YYYY-MM-DD.json`, you can ingest it into a local LLM + vector store:

```python
import json

with open("data/2026-04-22/rag_dataset_2026-04-22.json") as f:
    docs = json.load(f)

# For each doc, use the "text" field as the chunk
# and the other fields as metadata
for doc in docs:
    chunk = doc["text"]
    metadata = {k: v for k, v in doc.items() if k != "text"}
    # send to vector store: vector_store.add(chunk, metadata=metadata)
```

## Storing Exports Over Time

To build up a dataset over multiple days:

```bash
# Script to export all recent data
for day in {1..30}; do
  date=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(days=$day)).strftime('%Y-%m-%d'))")
  python3 export_data.py --date $date
done

# See all exports
ls data/
# data/2026-04-01/  data/2026-04-02/  ... data/2026-04-22/
```

Then concatenate all `rag_dataset_*.json` files for bulk import:

```bash
python3 << 'EOF'
import json
import glob

all_docs = []
for file in sorted(glob.glob("data/*/rag_dataset_*.json")):
    with open(file) as f:
        all_docs.extend(json.load(f))

with open("all_rag_data.json", "w") as f:
    json.dump(all_docs, f, indent=2)
    
print(f"Combined {len(all_docs)} documents into all_rag_data.json")
EOF
```

## Troubleshooting

**"relation 'arrivals' does not exist"**
- Run the poller at least once: `python3 poller.py` (let it run for 30 sec, then Ctrl+C)

**No records exported for a date**
- The poller may not have been running on that date
- Check the database: `python3 -c "import psycopg2; ...; SELECT COUNT(*) FROM arrivals WHERE DATE(recorded_at) = '2026-04-21';"`

**Large file sizes**
- `raw.json` and `raw.csv` can be large (1–5 MB per day for 300+ stops)
- `rag_dataset.json` is much smaller (~100 KB) and is the preferred format for RAG
- Consider deleting raw files after archiving if disk space is limited
