-- ISS Metrics Database Schema
-- Stores International Space Station telemetry data (Experimental)

-- Create the telemetry table
CREATE TABLE IF NOT EXISTS telemetry (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    level NUMERIC(10, 4),                        -- Urine tank level or other metric
    metric_name VARCHAR(255) DEFAULT 'URINE_TANK_LEVEL',  -- Name of the metric being tracked
    raw_data TEXT,                               -- Store raw data for debugging
    
    CONSTRAINT telemetry_check_level CHECK (level >= 0)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_iss_timestamp ON telemetry(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_iss_metric_name ON telemetry(metric_name);
CREATE INDEX IF NOT EXISTS idx_iss_composite ON telemetry(metric_name, timestamp DESC);

-- Create view for latest readings
CREATE OR REPLACE VIEW latest_iss_telemetry AS
SELECT DISTINCT ON (metric_name)
    id,
    timestamp,
    level,
    metric_name,
    raw_data
FROM telemetry
ORDER BY metric_name, timestamp DESC;

-- Create view for telemetry summary
CREATE OR REPLACE VIEW iss_telemetry_summary AS
SELECT 
    metric_name,
    COUNT(*) as reading_count,
    AVG(level) as avg_level,
    MIN(level) as min_level,
    MAX(level) as max_level,
    MIN(timestamp) as first_reading,
    MAX(timestamp) as last_reading
FROM telemetry
WHERE level IS NOT NULL
GROUP BY metric_name;

COMMENT ON TABLE telemetry IS 'Stores ISS telemetry data from NASA Lightstreamer feed (experimental)';
COMMENT ON COLUMN telemetry.level IS 'Metric value (e.g., tank level percentage)';
COMMENT ON VIEW latest_iss_telemetry IS 'Shows the most recent reading for each metric';
COMMENT ON VIEW iss_telemetry_summary IS 'Provides statistical summary of ISS telemetry data';