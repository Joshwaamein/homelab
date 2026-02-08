import psycopg2
from ping3 import ping
from datetime import datetime
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, RaspberryPiConfig

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ENVIRONMENT_METRICS)

def insert_ping_metric(host, response_time):
    """Insert ping results into the database"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        with conn:
            with conn.cursor() as cur:
                # Use parameterized query to prevent SQL injection
                cur.execute("""
                    INSERT INTO pi_environment_metrics 
                    (metric, labels, value, timestamp)
                    VALUES (%s, %s, %s, %s)
                """, (
                    'ping_response_time',
                    f'host="{host}"',
                    response_time if response_time is not None else -1,
                    datetime.now()
                ))
        print(f"Inserted ping result for {host}")
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

def ping_host(host):
    """Ping a host and return response time in milliseconds"""
    try:
        response = ping(host, timeout=2, unit='ms')
        return response
    except Exception as e:
        print(f"Ping error: {e}")
        return None

if __name__ == "__main__":
    target_host = RaspberryPiConfig.PING_TARGET
    response_time = ping_host(target_host)
    
    if response_time is not None:
        print(f"Ping to {target_host} succeeded: {response_time:.2f}ms")
    else:
        print(f"Ping to {target_host} failed")
    
    insert_ping_metric(target_host, response_time)

