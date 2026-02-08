-- Environment Metrics Database Schema
-- Stores Raspberry Pi system metrics and monitoring data

-- Create the pi_environment_metrics table
CREATE TABLE IF NOT EXISTS pi_environment_metrics (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(255) NOT NULL,                -- Metric name (e.g., cpu_temp, memory_usage)
    labels TEXT,                                 -- Prometheus-style labels (e.g., 'host="ghost"')
    value DOUBLE PRECISION NOT NULL,             -- Metric value
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Time of collection
);

-- Create the pi4_environment_metrics table (for secondary Pi device)
CREATE TABLE IF NOT EXISTS pi4_environment_metrics (
    id SERIAL PRIMARY KEY,
    metric VARCHAR(255) NOT NULL,                -- Metric name
    labels TEXT,                                 -- Prometheus-style labels
    value DOUBLE PRECISION NOT NULL,             -- Metric value
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Time of collection
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_pi_env_metric ON pi_environment_metrics(metric);
CREATE INDEX IF NOT EXISTS idx_pi_env_timestamp ON pi_environment_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_pi_env_metric_timestamp ON pi_environment_metrics(metric, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_pi4_env_metric ON pi4_environment_metrics(metric);
CREATE INDEX IF NOT EXISTS idx_pi4_env_timestamp ON pi4_environment_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_pi4_env_metric_timestamp ON pi4_environment_metrics(metric, timestamp DESC);

-- Create view for latest metrics (pi)
CREATE OR REPLACE VIEW latest_pi_metrics AS
SELECT DISTINCT ON (metric, labels)
    id,
    metric,
    labels,
    value,
    timestamp
FROM pi_environment_metrics
ORDER BY metric, labels, timestamp DESC;

-- Create view for latest metrics (pi4)
CREATE OR REPLACE VIEW latest_pi4_metrics AS
SELECT DISTINCT ON (metric, labels)
    id,
    metric,
    labels,
    value,
    timestamp
FROM pi4_environment_metrics
ORDER BY metric, labels, timestamp DESC;

-- Create view for metric summary
CREATE OR REPLACE VIEW metrics_summary AS
SELECT 
    'pi' as device,
    metric,
    COUNT(*) as reading_count,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    MIN(timestamp) as first_reading,
    MAX(timestamp) as last_reading
FROM pi_environment_metrics
GROUP BY metric
UNION ALL
SELECT 
    'pi4' as device,
    metric,
    COUNT(*) as reading_count,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    MIN(timestamp) as first_reading,
    MAX(timestamp) as last_reading
FROM pi4_environment_metrics
GROUP BY metric;

COMMENT ON TABLE pi_environment_metrics IS 'Stores Raspberry Pi system and network metrics';
COMMENT ON TABLE pi4_environment_metrics IS 'Stores secondary Raspberry Pi (Pi4) system metrics';
COMMENT ON VIEW latest_pi_metrics IS 'Shows the most recent value for each metric';
COMMENT ON VIEW metrics_summary IS 'Provides statistical summary of collected metrics';