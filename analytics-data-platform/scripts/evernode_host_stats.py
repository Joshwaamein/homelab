import requests
import psycopg2
from datetime import datetime, timezone
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, EvernodeConfig

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.EVERNODE_HOST_STATS)
API_URL = EvernodeConfig.API_URL

COLUMNS = [
    "key", "addressKey", "address", "cpuModelName", "cpuCount", "cpuMHz", "cpuMicrosec",
    "ramMb", "diskMb", "email", "accumulatedRewardAmount", "uriTokenId", "countryCode",
    "description", "registrationLedger", "registrationFee", "maxInstances", "activeInstances",
    "lastHeartbeatIndex", "version", "isATransferer", "lastVoteCandidateIdx", "lastVoteTimestamp",
    "supportVoteSent", "registrationTimestamp", "hostReputation", "reputedOnHeartbeat",
    "transferTimestamp", "leaseAmount", "active", "domain", "domainTLD", "hostRating",
    "hostRatingStr", "scoreMoment", "scoreNumerator", "scoreDenominator", "score", "score100",
    "score255", "scoreLastResetMoment", "scoreLastScoredMoment", "scoreLastUniverseSize",
    "scoreValid", "execution_ts"
]

def fetch_hosts():
    """Fetch all host entries with host fields."""
    resp = requests.get(API_URL, timeout=15)
    resp.raise_for_status()
    data = resp.json()
    return [
        entry for entry in data.get("data", [])
        if "cpuModelName" in entry
    ]

def insert_hosts(conn, hosts, execution_ts):
    """Insert all host records, one row per host per execution."""
    placeholders = ', '.join(['%s'] * len(COLUMNS))
    sql = f"""
        INSERT INTO evernode_hosts ({', '.join(COLUMNS)})
        VALUES ({placeholders})
    """
    with conn.cursor() as cur:
        for h in hosts:
            values = [h.get(col) for col in COLUMNS[:-1]]  # all columns except execution_ts
            values.append(execution_ts)
            cur.execute(sql, values)
    conn.commit()

def main():
    try:
        execution_ts = datetime.now(timezone.utc)
        hosts = fetch_hosts()
        if not hosts:
            print("No host entries found.")
            return
        with psycopg2.connect(**DB_CONFIG) as conn:
            insert_hosts(conn, hosts, execution_ts)
            print(f"{len(hosts)} host records inserted at {execution_ts.isoformat()} UTC.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()

