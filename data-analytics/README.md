# Data Collection System

A comprehensive monitoring and data collection system for tracking cryptocurrency balances across multiple blockchains (XRPL, Xahau, Ethereum), Raspberry Pi system metrics, Evernode host statistics, and experimental ISS telemetry.

## Features

- **Multi-chain Crypto Balance Tracking**
  - XRPL (XRP Ledger) balance monitoring
  - Xahau network balance monitoring with USD valuations
  - Ethereum and ERC20 token tracking
  - Polygon/Matic token balance checking (in tests)

- **Raspberry Pi Monitoring**
  - Prometheus metrics collection
  - Network latency monitoring
  - Internet speed testing

- **Evernode Network Monitoring**
  - Host statistics and performance metrics
  - Historical snapshots for trend analysis

- **ISS Telemetry** (Experimental)
  - International Space Station data collection via WebSocket

## Prerequisites

- Python 3.7+
- PostgreSQL database
- API keys for:
  - Moralis (for Ethereum token data)
  - Alchemy (for Polygon data)
  - Infura or similar Web3 provider (for Ethereum)

## Installation

### Quick Start

1. **Clone or navigate to the repository:**
   ```bash
   cd /root/pve-data
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   nano .env
   ```
   **Important**: Configure your API keys, database credentials, and account addresses in `.env`

3. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the setup script:**
   ```bash
   ./setup.sh
   ```
   This will:
   - Create all required PostgreSQL databases
   - Create tables with proper indexes
   - Create helpful database views
   - Verify your configuration

5. **Test your setup:**
   ```bash
   python tests/test.py
   ```

### Manual Database Setup

If you prefer to set up databases manually, SQL schema files are provided in the `sql/` directory:

```bash
# Create databases
psql -U root -c "CREATE DATABASE asset_balances;"
psql -U root -c "CREATE DATABASE environment_metrics;"
psql -U root -c "CREATE DATABASE evernode_host_stats;"
psql -U root -c "CREATE DATABASE iss_metrics;"

# Create tables and views
psql -U root -d asset_balances -f sql/asset_balances.sql
psql -U root -d environment_metrics -f sql/environment_metrics.sql
psql -U root -d evernode_host_stats -f sql/evernode_host_stats.sql
psql -U root -d iss_metrics -f sql/iss_metrics.sql
```

### Database Schema

The system uses multiple PostgreSQL databases:
- `asset_balances` - Crypto balance data with USD valuations
- `environment_metrics` - Raspberry Pi system metrics  
- `evernode_host_stats` - Evernode host performance data
- `iss_metrics` - ISS telemetry (experimental)

Each database includes views for easy querying:
- `latest_balances` - Most recent balance for each account/asset
- `portfolio_summary` - Total portfolio value by blockchain
- `latest_pi_metrics` - Most recent Pi system metrics
- `evernode_summary` - Aggregate Evernode host statistics

## Configuration

### Environment Variables (.env)

All sensitive data and configuration is stored in the `.env` file. Key settings include:

#### Database Settings
```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=root
DB_PASSWORD=your_password_here
```

#### API Keys
```bash
MORALIS_API_KEY=your_moralis_key
ALCHEMY_API_KEY=your_alchemy_key
```

#### Account Lists
Accounts are stored in comma-separated `ADDRESS:NAME` format:
```bash
XRPL_ACCOUNTS=rAddress1:wallet-name1,rAddress2:wallet-name2
XAHAU_ACCOUNTS=rAddress1:evr-host1,rAddress2:evr-host2
ETH_ACCOUNTS=0xAddress1:eth-wallet1
```

#### RPC Endpoints
```bash
XRPL_RPC_URL=https://s2.ripple.com:51234/
XAHAU_RPC_URL=https://xahau.network
WEB3_PROVIDER_URL=https://mainnet.infura.io/v3/YOUR_KEY
```

See `.env.example` for a complete configuration template.

## Usage

### Running Individual Scripts

#### XRPL Balance Checker
```bash
python scripts/xrpl_check_balances.py
```
Monitors XRP and trust line balances for configured XRPL accounts.

#### Xahau Balance Checker
```bash
python scripts/xahau_check_balances.py
```
Tracks XAH and token balances with USD valuations via CoinGecko.

#### Ethereum Balance Checker
```bash
python scripts/eth_check_balances.py
```
Monitors ETH and ERC20 token balances using Moralis API.

#### Raspberry Pi Metrics Collector
```bash
python scripts/pi_data_collector.py
```
Scrapes Prometheus metrics from configured endpoint.

#### Network Latency Monitor
```bash
python scripts/pi_latency_collector.py
```
Pings target host and records response times.

#### Speed Test
```bash
python scripts/pi4_speedtest-cli_collector.py
```
Runs internet speed test and stores results.

#### Evernode Host Stats
```bash
python scripts/evernode_host_stats.py
```
Fetches and stores Evernode host statistics.

### Automated Execution (Cron)

Set up cron jobs for regular data collection:

```bash
# Edit crontab
crontab -e

# Example: Run balance checks every hour
0 * * * * cd /root/pve-data && python scripts/xrpl_check_balances.py >> xrpl_check_balances.py-output.log 2>&1
0 * * * * cd /root/pve-data && python scripts/xahau_check_balances.py >> xahau_check_balances.py-output.log 2>&1

# Example: Run Pi metrics every 5 minutes
*/5 * * * * cd /root/pve-data && python scripts/pi_data_collector.py >> pi_data_collector.py-output.log 2>&1

# Example: Run speed test every 6 hours
0 */6 * * * cd /root/pve-data && python scripts/pi4_speedtest-cli_collector.py >> pi4_speedtest-cli_collector.py-output.log 2>&1
```

## Project Structure

```
/root/pve-data/
├── .env                    # Environment variables (DO NOT COMMIT)
├── .env.example           # Environment template
├── .gitignore             # Git ignore rules
├── config.py              # Centralized configuration
├── requirements.txt       # Python dependencies
├── setup.sh               # Database setup script
├── README.md             # This file
├── scripts/              # Production data collection scripts
│   ├── xrpl_check_balances.py
│   ├── xahau_check_balances.py
│   ├── eth_check_balances.py
│   ├── pi_data_collector.py
│   ├── pi_latency_collector.py
│   ├── pi4_speedtest-cli_collector.py
│   ├── evernode_host_stats.py
│   └── iss_collector.py
├── utils/                # Shared utility functions
│   ├── __init__.py
│   └── common.py
├── sql/                  # Database schema definitions
│   ├── asset_balances.sql
│   ├── environment_metrics.sql
│   ├── evernode_host_stats.sql
│   └── iss_metrics.sql
├── dashboards/           # Grafana dashboard JSON files
│   └── README.md
├── tests/                # Test scripts
│   ├── polygon_check_balances.py
│   └── test.py
└── *.log                 # Output logs (ignored by git)
```

## Database Schema

### asset_balances
Stores cryptocurrency balance data across multiple chains.

| Column | Type | Description |
|--------|------|-------------|
| source | VARCHAR | Blockchain source (xrpl, xahau, ethereum) |
| account | VARCHAR | Wallet address |
| name | VARCHAR | Account nickname |
| asset_type | VARCHAR | Asset symbol (XRP, XAH, EVR, ETH, etc.) |
| balance | NUMERIC | Token balance |
| usd_price | NUMERIC | USD price per token |
| usd_value | NUMERIC | Total USD value |
| domain | VARCHAR | Domain associated with account |
| ts | TIMESTAMP | Timestamp |
| execution_id | BIGINT | Batch execution ID |

### pi_environment_metrics / pi4_environment_metrics
Stores Raspberry Pi system metrics.

| Column | Type | Description |
|--------|------|-------------|
| metric | VARCHAR | Metric name |
| labels | TEXT | Prometheus-style labels |
| value | DOUBLE | Metric value |
| timestamp | TIMESTAMP | Collection time |

### evernode_hosts
Stores Evernode host statistics (43 columns including CPU, RAM, reputation, etc.).

## Features & Best Practices

### Security
- All sensitive data (API keys, addresses) stored in `.env`
- `.env` file excluded from git via `.gitignore`
- Database credentials centralized in config

### Code Quality
- Shared utilities reduce code duplication
- Centralized configuration management
- Consistent error handling
- Rate limiting with exponential backoff
- Price caching (5-minute TTL)

### Monitoring
- All scripts log to individual `.log` files
- Console output with color-coded messages
- Database error handling and rollback

## Grafana Dashboards

Grafana dashboard JSON files can be stored in the `dashboards/` directory. See `dashboards/README.md` for:
- Instructions on exporting/importing dashboards
- Example SQL queries for visualizations
- Data source configuration
- Dashboard naming conventions

You can place your existing dashboard JSON files in that directory for version control and easy deployment.

## Troubleshooting

### Setup Script Issues
```
Error: .env file not found!
```
**Solution:** Copy `.env.example` to `.env` and configure it before running `setup.sh`

### Missing API Keys Warning
```
⚠️  Warning: Missing API keys in .env file: MORALIS_API_KEY, ALCHEMY_API_KEY
```
**Solution:** Edit `.env` file and add the required API keys. Some scripts won't work without them.

### Database Connection Errors
```
Failed to connect to database: ...
```
**Solution:** 
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check database exists: `psql -U root -l`
- Verify credentials in `.env` file
- Run `./setup.sh` to create databases

### Database Already Exists
```
ERROR: database "asset_balances" already exists
```
**Solution:** This is normal - the setup script checks for existing databases. If you need to recreate tables, drop and recreate the database or manually run the SQL files.

### Rate Limiting Errors
```
⚠️ Rate limited. Retry 1/5 in 2.3s
```
**Solution:** Scripts automatically retry with exponential backoff. Reduce frequency of cron jobs if persistent.

### Import Errors
```
ModuleNotFoundError: No module named 'xrpl'
```
**Solution:** Install dependencies: `pip install -r requirements.txt`

### Test Script Failures
Run the test script to diagnose issues:
```bash
python tests/test.py
```
This will check:
- Database connectivity
- Configuration loading
- API reachability

## Development

### Adding New Accounts
Edit `.env` file and add to the appropriate account list:
```bash
XRPL_ACCOUNTS=existing_addr:name,new_addr:new_name
```

### Adding New Scripts
1. Import config: `from config import DatabaseConfig, ...`
2. Use shared utilities: `from utils import make_request_with_retry, ...`
3. Load config: `DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ASSET_BALANCES)`
4. Follow existing patterns for error handling and logging

### Database Schema Changes
1. Update the appropriate SQL file in `sql/` directory
2. Test the schema: `psql -U root -d database_name -f sql/schema_file.sql`
3. Document changes in this README
4. Consider data migration if tables already have data

### Adding Dashboards
1. Create your dashboard in Grafana
2. Export as JSON
3. Save to `dashboards/` directory
4. Document queries and variables in `dashboards/README.md`

## Contributing

When making changes:
1. Never commit `.env` file (contains secrets)
2. Update `.env.example` if adding new config options
3. Update this README for new features
4. Follow existing code patterns and error handling

## License

Private project for personal use.

## Support

For issues or questions, use the `/reportbug` command in the application.