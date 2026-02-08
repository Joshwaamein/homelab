import re
import requests
import psycopg2
from psycopg2.extras import execute_values
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, RaspberryPiConfig

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ENVIRONMENT_METRICS)

print(f"Connecting to database: {DB_CONFIG['dbname']}")

# SQL to create the table if it doesn't exist
create_table_sql = """
CREATE TABLE IF NOT EXISTS pi_environment_metrics (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(255) NOT NULL,
    labels TEXT,
    value DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

# SQL for bulk insert
insert_sql = """
INSERT INTO pi_environment_metrics (metric, labels, value)
VALUES %s
"""

# Regular expression to parse Prometheus metrics
pattern = re.compile(
    r'^(?P<name>[a-zA-Z0-9_:]+)'
    r'(?:{(?P<labels>[^}]+)})?\s+'
    r'(?P<value>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)',
    re.MULTILINE
)

# Fetch metrics from the endpoint
response = requests.get(RaspberryPiConfig.METRICS_URL)
data = response.text

# Parse metrics into a dictionary
metrics = {}
for match in pattern.finditer(data):
    groups = match.groupdict()
    name = groups['name']
    labels = groups['labels']
    value = float(groups['value'])

    if labels:
        # Parse labels into tuple of key-value pairs
        label_pairs = []
        for label in labels.split(','):
            k, v = label.split('=')
            label_pairs.append((k.strip(), v.strip().strip('"')))
        labels_tuple = tuple(label_pairs)
    else:
        labels_tuple = None

    metrics[(name, labels_tuple)] = value

# Prepare data for insertion
metrics_list = []
for (metric, labels), value in metrics.items():
    if labels is None:
        labels_str = None
    else:
        labels_str = ','.join(f'{k}="{v}"' for k, v in labels)
    metrics_list.append((metric, labels_str, value))

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

insert_metrics_to_db(DB_CONFIG, metrics_list)
