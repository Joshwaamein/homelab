# Pi Metrics Dashboard - Improvements Implemented

## ✅ Database Views Created

The following SQL views have been created in the `environment_metrics` database:

### 1. pi_comfort_index
Calculates comfort level based on temperature and humidity combinations.

**Columns:**
- `timestamp` - Time of measurement
- `temperature` - Room temperature (°C)
- `humidity` - Room humidity (%)
- `comfort_score` - Numeric score (25-100)
- `comfort_level` - Text: 'Optimal', 'Comfortable', or 'Uncomfortable'

**Usage in Grafana:**
```sql
SELECT comfort_level 
FROM pi_comfort_index 
ORDER BY timestamp DESC 
LIMIT 1
```

### 2. pi_network_quality
Hourly network statistics with quality scoring.

**Columns:**
- `timestamp` - Hour bucket
- `avg_ping` - Average ping (ms)
- `min_ping` - Best ping (ms)
- `max_ping` - Worst ping (ms)
- `packet_loss_pct` - Packet loss percentage
- `network_quality_score` - Score 0-100 (higher is better)

**Usage in Grafana:**
```sql
SELECT 
  timestamp as time,
  network_quality_score as "Quality %"
FROM pi_network_quality
WHERE $__timeFilter(timestamp)
ORDER BY timestamp
```

### 3. latest_network_stats
Current network metrics snapshot.

**Columns:**
- `current_ping_ms` - Latest ping
- `avg_ping_24h` - 24-hour average
- `packet_loss_24h` - 24-hour packet loss %
- `download_mbps` - Latest download speed
- `upload_mbps` - Latest upload speed

### 4. latest_environmental_stats
Current environmental metrics snapshot.

**Columns:**
- `current_temp` - Current room temperature
- `current_humidity` - Current humidity
- `forecast_temp` - Forecast temperature
- `forecast_humidity` - Forecast humidity  
- `avg_temp_24h` - 24-hour average temp
- `avg_humidity_24h` - 24-hour average humidity

### 5. pi_temp_heatmap
Temperature patterns by hour and day of week.

**Columns:**
- `hour_of_day` - 0-23
- `day_of_week` - 0-6 (Sunday=0)
- `avg_temperature` - Average temp for that hour/day

## 🎨 Recommended Dashboard Layout

### Row 1: Overview Stats (Height: 8)
```
┌──────────┬──────────┬──────────┬──────────┐
│ 🌡️ Temp  │ 💧 Humid │ 😊 Comf  │ 📡 Ping  │
│  Gauge   │  Gauge   │  Stat    │  Gauge   │
│  6 wide  │  6 wide  │  6 wide  │  6 wide  │
└──────────┴──────────┴──────────┴──────────┘
```

**Panel 1: Room Temperature (Gauge)**
- Query: `SELECT current_temp as "Temperature" FROM latest_environmental_stats`
- Thresholds: <18°C blue, 18-24°C green, 24-27°C yellow, 27-30°C orange, >30°C red
- Show current value with color indicator

**Panel 2: Room Humidity (Gauge)**
- Query: `SELECT current_humidity as "Humidity" FROM latest_environmental_stats`
- Thresholds: <30% red, 30-40% yellow, 40-60% green, 60-70% yellow, 70-80% orange, >80% red
- Ideal range 40-60%

**Panel 3: Comfort Level (Stat)**
- Query: `SELECT comfort_level FROM pi_comfort_index ORDER BY timestamp DESC LIMIT 1`
- Mapping: Optimal=😊 green, Comfortable=🙂 yellow, Uncomfortable=😰 red
- Large emoji display

**Panel 4: Network Latency (Gauge)**
- Query: `SELECT current_ping_ms as "Latency" FROM latest_network_stats`
- Thresholds: <20ms red, 20-50ms orange, 50-100ms yellow, >100ms green
- Inverted colors (lower is better)

### Row 2: Temperature & Humidity Trends (Height: 9)
```
┌─────────────────────┬─────────────────────┐
│ 📈 Temperature      │ 📈 Humidity         │
│  Time Series        │  Time Series        │
│  12 wide            │  12 wide            │
└─────────────────────┴─────────────────────┘
```

**Panel 5: Temperature Comparison**
```sql
SELECT
  timestamp as time,
  CASE 
    WHEN metric = 'room_temperature_celsius' THEN 'Room'
    WHEN metric = 'forecast_temperature_celsius' THEN 'Forecast'
  END as metric,
  value
FROM pi_environment_metrics
WHERE metric IN ('room_temperature_celsius', 'forecast_temperature_celsius')
  AND $__timeFilter(timestamp)
ORDER BY timestamp
```
- Room = solid blue line with area fill
- Forecast = dashed orange line
- Legend shows: mean, current, max, min

**Panel 6: Humidity Comparison**
```sql
SELECT
  timestamp as time,
  CASE 
    WHEN metric = 'room_humidity_percent' THEN 'Room'
    WHEN metric = 'forecast_humidity_percent' THEN 'Forecast'
  END as metric,
  value
FROM pi_environment_metrics
WHERE metric IN ('room_humidity_percent', 'forecast_humidity_percent')
  AND $__timeFilter(timestamp)
ORDER BY timestamp
```
- Room = solid light-blue line
- Forecast = dashed orange line

### Row 3: Network Performance (Height: 9)
```
┌─────────────────────┬─────────────────────┐
│ 🌐 Latency          │ 🚀 Speed Tests      │
│  Time Series        │  Time Series        │
│  12 wide            │  12 wide            │
└─────────────────────┴─────────────────────┘
```

**Panel 7: Network Latency**
```sql
SELECT
  timestamp as time,
  value as "Ping (ms)"
FROM pi_environment_metrics
WHERE metric = 'ping_response_time'
  AND value > 0
  AND $__timeFilter(timestamp)
ORDER BY timestamp
```
- Threshold lines at 100ms (yellow) and 200ms (red)
- Exclude failed pings (value = -1)

**Panel 8: Internet Speed**
```sql
SELECT
  timestamp as time,
  CASE
    WHEN metric = 'internet_download_speed_mbps' THEN 'Download'
    WHEN metric = 'internet_upload_speed_mbps' THEN 'Upload'
  END as metric,
  value
FROM pi_environment_metrics
WHERE metric IN ('internet_download_speed_mbps', 'internet_upload_speed_mbps')
  AND $__timeFilter(timestamp)
ORDER BY timestamp
```
- Download = green line
- Upload = blue line

### Row 4: Network Stats (Height: 5)
```
┌──────────┬──────────┬──────────┐
│ 📉 Loss  │ 📊 Speed │ ⭐ Score │
│  Stat    │  Stat    │  Gauge   │
│  8 wide  │  8 wide  │  8 wide  │
└──────────┴──────────┴──────────┘
```

**Panel 9: Packet Loss**
- Query: `SELECT COALESCE(packet_loss_pct, 0) as "Packet Loss" FROM pi_network_quality WHERE timestamp > NOW() - INTERVAL '24 hours' ORDER BY timestamp DESC LIMIT 1`
- Background color based on thresholds
- Thresholds: >10% red, 5-10% orange, 1-5% yellow, <1% green

**Panel 10: Latest Speed Test**
- Query: `SELECT download_mbps as "Download", upload_mbps as "Upload" FROM latest_network_stats`
- Side-by-side stat display
- Shows download and upload with sparklines

**Panel 11: Network Quality Score**
- Query: `SELECT network_quality_score as "Quality Score" FROM pi_network_quality ORDER BY timestamp DESC LIMIT 1`
- Gauge visualization
- Score 0-100 (combines ping and packet loss)
- Thresholds: <25 red, 25-50 orange, 50-75 yellow, 75-90 green, >90 dark-green

## 🎯 Key Improvements Over Original

### Visual Enhancements
- ✅ **Color-coded gauges** with meaningful thresholds
- ✅ **Emoji indicators** for comfort level
- ✅ **Forecast comparison** with dashed lines
- ✅ **Area fills** for better trend visibility
- ✅ **Smooth line interpolation** for cleaner graphs
- ✅ **Legend tables** showing mean/max/min values

### Functional Improvements
- ✅ **Calculated metrics** (comfort level, network quality)
- ✅ **Packet loss tracking** (previously missing)
- ✅ **Smart thresholds** based on acceptable ranges
- ✅ **Sparklines in stat panels** for quick trend viewing
- ✅ **Better organization** with logical grouping

### Data Insights
- ✅ **Room vs Forecast comparison** shows prediction accuracy
- ✅ **Comfort index** combines temp + humidity meaningfully
- ✅ **Network quality score** gives single metric for health
- ✅ **24-hour aggregations** for reliable statistics

## 📋 Import Instructions

### Option 1: Manual Import to Grafana
1. Open Grafana → Dashboards → Import
2. Upload `PiMetrics-Improved.json`
3. Select PostgreSQL data source for `environment_metrics` database
4. Save with name "Pi Metrics - Enhanced"

### Option 2: Update Existing Dashboard
1. Open your current "Pi Metrics" dashboard
2. Dashboard settings → JSON Model
3. Copy relevant panel configurations from `PiMetrics-Improved.json`
4. Paste and save

### Option 3: API Import
```bash
# Using Grafana API (requires API key)
curl -X POST http://your-grafana:3000/api/dashboards/db \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d @dashboards/PiMetrics-Improved.json
```

## 🔔 Recommended Alert Rules

### Create These Alerts in Grafana

**1. High Temperature Alert**
```
Name: Room Temperature Too High
Condition: current_temp > 28
For: 10 minutes
Severity: Warning

Condition: current_temp > 30
For: 5 minutes
Severity: Critical
```

**2. High Humidity Alert**
```
Name: High Humidity
Condition: current_humidity > 70
For: 30 minutes  
Severity: Warning

Condition: current_humidity > 80
For: 10 minutes
Severity: Critical
```

**3. Network Degraded Alert**
```
Name: Network Performance Degraded
Condition: network_quality_score < 50
For: 15 minutes
Severity: Warning
```

**4. Packet Loss Alert**
```
Name: High Packet Loss
Condition: packet_loss_24h > 10
For: 10 minutes
Severity: Critical
```

## 💡 Additional Enhancements to Consider

### 1. Add Variables
Create dashboard variables for dynamic filtering:
```
$timerange = 1h, 6h, 24h, 7d, 30d (default: 24h)
$refresh_interval = 30s, 1m, 5m, 15m (default: 1m)
$metric_type = All, Environmental, Network, System
```

### 2. Add More Panels
If you want even more insights:

**Temperature Heatmap (Day of Week × Hour)**
```sql
SELECT
  EXTRACT(HOUR FROM timestamp) as hour_of_day,
  EXTRACT(DOW FROM timestamp) as day_of_week,
  AVG(value) as avg_temperature
FROM pi_environment_metrics
WHERE metric = 'room_temperature_celsius'
  AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY EXTRACT(HOUR FROM timestamp), EXTRACT(DOW FROM timestamp)
```

**Forecast Accuracy Panel**
```sql
WITH forecast AS (
  SELECT 
    DATE_TRUNC('hour', timestamp - INTERVAL '24 hours') as forecast_hour,
    AVG(value) as forecast_value
  FROM pi_environment_metrics
  WHERE metric = 'forecast_temperature_celsius'
  GROUP BY DATE_TRUNC('hour', timestamp - INTERVAL '24 hours')
),
actual AS (
  SELECT
    DATE_TRUNC('hour', timestamp) as actual_hour,
    AVG(value) as actual_value
  FROM pi_environment_metrics
  WHERE metric = 'room_temperature_celsius'
  GROUP BY DATE_TRUNC('hour', timestamp)
)
SELECT 
  a.actual_hour as time,
  ABS(f.forecast_value - a.actual_value) as "Forecast Error (°C)"
FROM actual a
LEFT JOIN forecast f ON a.actual_hour = f.forecast_hour
WHERE a.actual_hour > NOW() - INTERVAL '7 days'
ORDER BY a.actual_hour
```

### 3. Add Annotations
Create annotations for significant events:
- Temperature spikes (>28°C)
- Network outages (packet loss >50%)
- Speed test results (<50 Mbps)

## 📊 Quick Reference SQL Queries

### Get Current Status (All Metrics)
```sql
SELECT 
  e.current_temp as "Temp (°C)",
  e.current_humidity as "Humidity (%)",
  c.comfort_level as "Comfort",
  n.current_ping_ms as "Ping (ms)",
  n.packet_loss_24h as "Loss (%)",
  n.download_mbps as "Download",
  n.upload_mbps as "Upload",
  q.network_quality_score as "Net Quality"
FROM latest_environmental_stats e,
     latest_network_stats n,
     (SELECT network_quality_score FROM pi_network_quality ORDER BY timestamp DESC LIMIT 1) q,
     (SELECT comfort_level FROM pi_comfort_index ORDER BY timestamp DESC LIMIT 1) c;
```

### Get 24-Hour Summary
```sql
SELECT 
  'Temperature' as metric,
  ROUND(MIN(value)::numeric, 2) as min,
  ROUND(AVG(value)::numeric, 2) as avg,
  ROUND(MAX(value)::numeric, 2) as max
FROM pi_environment_metrics
WHERE metric = 'room_temperature_celsius'
  AND timestamp > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
  'Humidity',
  ROUND(MIN(value)::numeric, 2),
  ROUND(AVG(value)::numeric, 2),
  ROUND(MAX(value)::numeric, 2)
FROM pi_environment_metrics
WHERE metric = 'room_humidity_percent'
  AND timestamp > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
  'Ping (ms)',
  ROUND(MIN(value)::numeric, 2),
  ROUND(AVG(value)::numeric, 2),
  ROUND(MAX(value)::numeric, 2)
FROM pi_environment_metrics
WHERE metric = 'ping_response_time'
  AND value > 0
  AND timestamp > NOW() - INTERVAL '24 hours';
```

## 🚀 Next Steps

1. **Import the improved dashboard** to Grafana
2. **Set up alerts** using the recommended rules above
3. **Customize thresholds** to match your environment
4. **Add more panels** based on your specific needs
5. **Share feedback** on what works best

## 📁 Files Created

- `/root/pve-data/sql/pi_metrics_views.sql` - Database views (already applied)
- `/root/pve-data/dashboards/PiMetrics-Improved.json` - Improved dashboard template
- This file - Implementation documentation

## 🎓 Tips for Using the Dashboard

### Time Range Selection
- **1 hour** - Real-time monitoring
- **6 hours** - Recent trends
- **24 hours** - Daily patterns (recommended default)
- **7 days** - Weekly patterns
- **30 days** - Monthly trends

### Understanding the Scores

**Comfort Score (0-100)**
- 100 = Optimal (18-24°C, 40-60% humidity)
- 75 = Comfortable  
- 50 = Acceptable
- 25 = Uncomfortable

**Network Quality Score (0-100)**
- Formula: `100 * (1 - ping/100) * (1 - packet_loss/20)`
- 90-100 = Excellent
- 75-90 = Good
- 50-75 = Fair
- <50 = Poor

### Color Meanings
- 🟢 **Green** - Optimal/Good
- 🟡 **Yellow** - Acceptable/Warning
- 🟠 **Orange** - Concerning
- 🔴 **Red** - Critical/Action needed
- 🔵 **Blue** - Neutral/Cool

## 🔧 Maintenance

### Updating Views
If you need to modify the views:
```bash
# Edit the SQL file
nano /root/pve-data/sql/pi_metrics_views.sql

# Reapply to database
psql -U root -d environment_metrics -f /root/pve-data/sql/pi_metrics_views.sql
```

### Testing Queries
Test dashboard queries before adding panels:
```bash
psql -U root -d environment_metrics
```

Then run your query to verify results.

---

**Created:** February 9, 2026
**Status:** Views applied, dashboard template created
**Next:** Import to Grafana and customize