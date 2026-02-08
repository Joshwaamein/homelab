# Grafana Dashboards

This directory contains Grafana dashboard JSON files for visualizing the collected data.

## Dashboard Files

Place your Grafana dashboard JSON exports here. The setup script can optionally import these dashboards automatically.

### Recommended Dashboards

1. **Crypto Portfolio Dashboard** - Visualize balances and USD values across XRPL, Xahau, and Ethereum
2. **Raspberry Pi Metrics** - System metrics, latency, and speed test results
3. **Evernode Host Stats** - Host performance, reputation, and network statistics
4. **ISS Telemetry** (Experimental) - Real-time ISS telemetry visualization

## Exporting Dashboards from Grafana

To export a dashboard:
1. Open your dashboard in Grafana
2. Click the share icon (top right)
3. Go to "Export" tab
4. Click "Save to file"
5. Save the JSON file to this directory

## Importing Dashboards

### Manual Import
1. Open Grafana
2. Click "+" → "Import"
3. Upload the JSON file or paste the JSON content
4. Select your PostgreSQL data source
5. Click "Import"

### Automated Import (Future Feature)
The `setup.sh` script can be extended to automatically import dashboards using the Grafana API.

## Data Source Configuration

All dashboards should use PostgreSQL data sources pointing to:
- **asset_balances** database for crypto data
- **environment_metrics** database for Pi metrics  
- **evernode_host_stats** database for Evernode data
- **iss_metrics** database for ISS telemetry

## Example Queries

### Latest Crypto Balances by Account
```sql
SELECT 
    name,
    asset_type,
    balance,
    usd_value,
    ts
FROM latest_balances
WHERE source = 'xahau'
ORDER BY usd_value DESC NULLS LAST;
```

### Portfolio Value Over Time
```sql
SELECT 
    ts as time,
    source,
    SUM(usd_value) as total_value
FROM asset_balances
WHERE usd_value IS NOT NULL
    AND ts > NOW() - INTERVAL '30 days'
GROUP BY ts, source
ORDER BY ts;
```

### Pi Metrics - CPU Temperature
```sql
SELECT 
    timestamp as time,
    value as temperature
FROM pi_environment_metrics
WHERE metric = 'cpu_temp'
    AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp;
```

### Evernode Hosts by Country
```sql
SELECT 
    countryCode as country,
    host_count,
    active_count,
    avg_reputation
FROM evernode_by_country
ORDER BY host_count DESC
LIMIT 10;
```

## Dashboard Naming Convention

Use descriptive names for your dashboard files:
- `crypto-portfolio.json`
- `pi-system-metrics.json`
- `evernode-network-stats.json`
- `iss-telemetry.json`

## Tips for Dashboard Creation

1. **Use Variables**: Create dashboard variables for source, account, metric names
2. **Time Ranges**: Set appropriate default time ranges (24h, 7d, 30d)
3. **Refresh Rates**: Set auto-refresh to match your data collection frequency
4. **Alerts**: Configure alerts for critical thresholds (low balances, high temperatures)
5. **Units**: Use appropriate units (%, USD, MB, ms, etc.)

## Contributing Your Dashboards

If you create useful dashboards, consider:
1. Documenting the queries used
2. Adding screenshots
3. Describing the use case
4. Noting any required data or setup

## Support

For Grafana-specific issues, consult the [Grafana Documentation](https://grafana.com/docs/).

For database schema questions, refer to the SQL files in the `sql/` directory.