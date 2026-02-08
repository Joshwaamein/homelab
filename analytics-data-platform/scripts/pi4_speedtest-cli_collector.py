import psycopg2
import speedtest
from psycopg2.extras import execute_values
from datetime import datetime
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ENVIRONMENT_METRICS)

print(f"Connecting to database: {DB_CONFIG['dbname']}")

# SQL to create the table if it doesn't exist
create_table_sql = """
CREATE TABLE IF NOT EXISTS pi4_environment_metrics (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(255) NOT NULL,
    labels TEXT,
    value DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

# SQL for bulk insert
insert_sql = """
INSERT INTO pi4_environment_metrics (metric, labels, value)
VALUES %s
"""

def run_speedtest():
    """Run speedtest and return download/upload speeds in Mbps"""
    try:
        st = speedtest.Speedtest()
        st.get_best_server()
        
        # Run tests
        download = st.download() / 1_000_000  # Convert to Mbps
        upload = st.upload() / 1_000_000
        
        return download, upload
    except Exception as e:
        print(f"Speedtest failed: {str(e)}")
        return None, None

# Prepare data for insertion
metrics_list = []

# Run speedtest and get results
download_speed, upload_speed = run_speedtest()

if download_speed is not None:
    metrics_list.append((
        "internet_download_speed_mbps", 
        None,  # No labels
        download_speed
    ))

if upload_speed is not None:
    metrics_list.append((
        "internet_upload_speed_mbps",
        None,  # No labels
        upload_speed
    ))

# Insert metrics into PostgreSQL
def insert_metrics_to_db(db_config, data):
    conn = None
    try:
        conn = psycopg2.connect(**db_config)
        with conn:
            with conn.cursor() as cur:
                cur.execute(create_table_sql)
                execute_values(
                    cur,
                    insert_sql,
                    data,
                    template="(%s, %s, %s)"
                )
        print(f"Inserted {len(data)} metrics successfully")
    except Exception as e:
        print(f"Database error: {str(e)}")
    finally:
        if conn:
            conn.close()

if metrics_list:
    insert_metrics_to_db(DB_CONFIG, metrics_list)
else:
    print("No speedtest results to insert")

