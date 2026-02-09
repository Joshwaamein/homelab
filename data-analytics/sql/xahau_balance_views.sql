-- Enhanced Views for Xahau Balances
-- Run on asset_balances database

-- Latest Xahau balances per account
CREATE OR REPLACE VIEW latest_xahau_balances AS
SELECT DISTINCT ON (source, account, asset_type)
    id,
    source,
    account,
    name,
    asset_type,
    balance,
    usd_price,
    usd_value,
    domain,
    ts,
    execution_id
FROM asset_balances
WHERE source = 'xahau'
ORDER BY source, account, asset_type, ts DESC;

-- Xahau portfolio summary
CREATE OR REPLACE VIEW xahau_portfolio_summary AS
SELECT 
    COUNT(DISTINCT account) as total_accounts,
    SUM(CASE WHEN asset_type = 'XAH' THEN balance ELSE 0 END) as total_xah,
    SUM(CASE WHEN asset_type = 'EVR' THEN balance ELSE 0 END) as total_evr,
    SUM(COALESCE(usd_value, 0)) as total_usd_value,
    (SELECT usd_price FROM latest_xahau_balances WHERE asset_type = 'XAH' LIMIT 1) as xah_price,
    (SELECT usd_price FROM latest_xahau_balances WHERE asset_type = 'EVR' LIMIT 1) as evr_price,
    MAX(ts) as last_updated
FROM latest_xahau_balances
WHERE usd_value IS NOT NULL;

-- Balance by host (combines main + reputationd accounts)
CREATE OR REPLACE VIEW xahau_balance_by_host AS
WITH host_accounts AS (
    SELECT 
        CASE 
            WHEN name LIKE '%evr1%' THEN 'pve-evr1'
            WHEN name LIKE '%evr2%' THEN 'pve-evr2'
            WHEN name LIKE '%evr3%' THEN 'pve-evr3'
            WHEN name LIKE '%evr4%' THEN 'pve-evr4'
            ELSE name
        END as host_name,
        asset_type,
        balance,
        usd_value,
        ts
    FROM latest_xahau_balances
)
SELECT 
    host_name,
    SUM(CASE WHEN asset_type = 'XAH' THEN balance ELSE 0 END) as total_xah,
    SUM(CASE WHEN asset_type = 'EVR' THEN balance ELSE 0 END) as total_evr,
    SUM(COALESCE(usd_value, 0)) as total_usd_value,
    MAX(ts) as last_updated
FROM host_accounts
GROUP BY host_name
ORDER BY host_name;

-- Balance trends for time series
CREATE OR REPLACE VIEW xahau_balance_trends AS
SELECT 
    ts as timestamp,
    name,
    asset_type,
    balance,
    usd_value
FROM asset_balances
WHERE source = 'xahau'
    AND ts > NOW() - INTERVAL '30 days'
ORDER BY ts DESC;

-- Account-level summary (main vs reputationd)
CREATE OR REPLACE VIEW xahau_account_summary AS
SELECT 
    name,
    SUM(CASE WHEN asset_type = 'XAH' THEN balance ELSE 0 END) as xah_balance,
    SUM(CASE WHEN asset_type = 'EVR' THEN balance ELSE 0 END) as evr_balance,
    SUM(COALESCE(usd_value, 0)) as total_usd,
    CASE 
        WHEN name LIKE '%reputationd%' THEN 'Reputation Daemon'
        ELSE 'Main Account'
    END as account_type
FROM latest_xahau_balances
GROUP BY name
ORDER BY name;

COMMENT ON VIEW latest_xahau_balances IS 'Most recent balance for each Xahau account';
COMMENT ON VIEW xahau_portfolio_summary IS 'Total portfolio metrics across all accounts';
COMMENT ON VIEW xahau_balance_by_host IS 'Aggregated balances per host (main + reputationd)';
COMMENT ON VIEW xahau_balance_trends IS 'Historical balance data for time series';
COMMENT ON VIEW xahau_account_summary IS 'Per-account summary with account type classification';