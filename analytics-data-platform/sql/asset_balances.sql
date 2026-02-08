-- Asset Balances Database Schema
-- Stores cryptocurrency balance data across multiple blockchains

-- Create the main asset_balances table
CREATE TABLE IF NOT EXISTS asset_balances (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL,           -- Blockchain source (xrpl, xahau, ethereum)
    account VARCHAR(255) NOT NULL,         -- Wallet address
    name VARCHAR(255),                     -- Account nickname/label
    asset_type VARCHAR(50) NOT NULL,       -- Asset symbol (XRP, XAH, EVR, ETH, etc.)
    balance NUMERIC(30, 10) NOT NULL,      -- Token balance
    usd_price NUMERIC(20, 8),              -- USD price per token at time of collection
    usd_value NUMERIC(30, 2),              -- Total USD value (balance * usd_price)
    domain VARCHAR(255),                   -- Domain associated with account (if any)
    ts TIMESTAMP NOT NULL DEFAULT NOW(),   -- Timestamp of data collection
    execution_id BIGINT,                   -- Batch execution ID for grouping related records
    
    -- Indexes for common queries
    CONSTRAINT asset_balances_check_positive_balance CHECK (balance >= 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_asset_balances_source ON asset_balances(source);
CREATE INDEX IF NOT EXISTS idx_asset_balances_account ON asset_balances(account);
CREATE INDEX IF NOT EXISTS idx_asset_balances_asset_type ON asset_balances(asset_type);
CREATE INDEX IF NOT EXISTS idx_asset_balances_ts ON asset_balances(ts DESC);
CREATE INDEX IF NOT EXISTS idx_asset_balances_execution_id ON asset_balances(execution_id);
CREATE INDEX IF NOT EXISTS idx_asset_balances_composite ON asset_balances(source, account, asset_type, ts DESC);

-- Create a view for latest balances per account/asset
CREATE OR REPLACE VIEW latest_balances AS
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
ORDER BY source, account, asset_type, ts DESC;

-- Create a view for total portfolio value by source
CREATE OR REPLACE VIEW portfolio_summary AS
SELECT 
    source,
    COUNT(DISTINCT account) as account_count,
    COUNT(DISTINCT asset_type) as asset_count,
    SUM(usd_value) as total_usd_value,
    MAX(ts) as last_updated
FROM latest_balances
WHERE usd_value IS NOT NULL
GROUP BY source;

COMMENT ON TABLE asset_balances IS 'Stores cryptocurrency balance data from multiple blockchain sources';
COMMENT ON COLUMN asset_balances.execution_id IS 'Groups records collected in the same batch run';
COMMENT ON VIEW latest_balances IS 'Shows the most recent balance for each account/asset combination';
COMMENT ON VIEW portfolio_summary IS 'Summarizes total portfolio value by blockchain source';