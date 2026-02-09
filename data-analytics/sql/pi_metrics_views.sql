-- Additional Views for Enhanced Pi Metrics Dashboard
-- Run this after environment_metrics.sql

-- Comfort index calculation
CREATE OR REPLACE VIEW pi_comfort_index AS
SELECT 
  t.timestamp,
  t.value as temperature,
  h.value as humidity,
  CASE
    WHEN t.value BETWEEN 18 AND 24 AND h.value BETWEEN 40 AND 60 THEN 100
    WHEN t.value BETWEEN 15 AND 27 AND h.value BETWEEN 30 AND 70 THEN 75
    WHEN t.value BETWEEN 12 AND 30 AND h.value BETWEEN 20 AND 80 THEN 50
    ELSE 25
  END as comfort_score,
  CASE
    WHEN t.value BETWEEN 18 AND 24 AND h.value BETWEEN 40 AND 60 THEN 'Optimal'
    WHEN t.value BETWEEN 15 AND 27 AND h.value BETWEEN 30 AND 70 THEN 'Comfortable'
    ELSE 'Uncomfortable'
  END as comfort_level
FROM 
  (SELECT timestamp, value FROM pi_environment_metrics WHERE metric = 'room_temperature_celsius') t
JOIN
  (SELECT timestamp, value FROM pi_environment_metrics WHERE metric = 'room_humidity_percent') h
  ON DATE_TRUNC('minute', t.timestamp) = DATE_TRUNC('minute', h.timestamp)
WHERE t.timestamp > NOW() - INTERVAL '30 days';

-- Network quality metrics
CREATE OR REPLACE VIEW pi_network_quality AS
WITH ping_stats AS (
  SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    AVG(value) FILTER (WHERE value > 0) as avg_ping,
    MIN(value) FILTER (WHERE value > 0) as min_ping,
    MAX(value) FILTER (WHERE value > 0) as max_ping,
    COUNT(*) FILTER (WHERE value = -1)::float / COUNT(*)::float * 100 as packet_loss_pct
  FROM pi_environment_metrics
  WHERE metric = 'ping_response_time'
    AND timestamp > NOW() - INTERVAL '7 days'
  GROUP BY DATE_TRUNC('hour', timestamp)
)
SELECT 
  hour as timestamp,
  avg_ping,
  min_ping,
  max_ping,
  packet_loss_pct,
  ROUND(
    100 * (1 - LEAST(avg_ping / 100, 1)) * 
    (1 - LEAST(packet_loss_pct / 20, 1))
  ) as network_quality_score
FROM ping_stats
ORDER BY hour DESC;

-- Latest network statistics
CREATE OR REPLACE VIEW latest_network_stats AS
SELECT
  (SELECT value FROM latest_pi_metrics WHERE metric = 'ping_response_time') as current_ping_ms,
  (SELECT AVG(value) FROM pi_environment_metrics 
   WHERE metric = 'ping_response_time' AND value > 0 AND timestamp > NOW() - INTERVAL '24 hours') as avg_ping_24h,
  (SELECT COUNT(*) FILTER (WHERE value = -1)::float / COUNT(*)::float * 100
   FROM pi_environment_metrics WHERE metric = 'ping_response_time' AND timestamp > NOW() - INTERVAL '24 hours') as packet_loss_24h,
  (SELECT value FROM latest_pi_metrics WHERE metric = 'internet_download_speed_mbps') as download_mbps,
  (SELECT value FROM latest_pi_metrics WHERE metric = 'internet_upload_speed_mbps') as upload_mbps;

-- Environmental statistics
CREATE OR REPLACE VIEW latest_environmental_stats AS
SELECT
  (SELECT value FROM latest_pi_metrics WHERE metric = 'room_temperature_celsius') as current_temp,
  (SELECT value FROM latest_pi_metrics WHERE metric = 'room_humidity_percent') as current_humidity,
  (SELECT value FROM latest_pi_metrics WHERE metric = 'forecast_temperature_celsius') as forecast_temp,
  (SELECT value FROM latest_pi_metrics WHERE metric = 'forecast_humidity_percent') as forecast_humidity,
  (SELECT AVG(value) FROM pi_environment_metrics 
   WHERE metric = 'room_temperature_celsius' AND timestamp > NOW() - INTERVAL '24 hours') as avg_temp_24h,
  (SELECT AVG(value) FROM pi_environment_metrics
   WHERE metric = 'room_humidity_percent' AND timestamp > NOW() - INTERVAL '24 hours') as avg_humidity_24h;

-- Hourly temperature heatmap data
CREATE OR REPLACE VIEW pi_temp_heatmap AS
SELECT
  EXTRACT(HOUR FROM timestamp) as hour_of_day,
  EXTRACT(DOW FROM timestamp) as day_of_week,
  AVG(value) as avg_temperature
FROM pi_environment_metrics
WHERE metric = 'room_temperature_celsius'
  AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM timestamp), EXTRACT(DOW FROM timestamp)
ORDER BY day_of_week, hour_of_day;

COMMENT ON VIEW pi_comfort_index IS 'Calculates comfort level based on temperature and humidity';
COMMENT ON VIEW pi_network_quality IS 'Hourly network quality metrics with quality score';
COMMENT ON VIEW latest_network_stats IS 'Current network statistics summary';
COMMENT ON VIEW latest_environmental_stats IS 'Current environmental metrics summary';
COMMENT ON VIEW pi_temp_heatmap IS 'Temperature patterns by hour of day and day of week';