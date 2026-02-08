-- Evernode Host Stats Database Schema
-- Stores Evernode network host statistics and performance data

-- Create the evernode_hosts table with all 43 columns
CREATE TABLE IF NOT EXISTS evernode_hosts (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255),
    addressKey VARCHAR(255),
    address VARCHAR(255),
    cpuModelName TEXT,
    cpuCount INTEGER,
    cpuMHz NUMERIC(10, 2),
    cpuMicrosec BIGINT,
    ramMb INTEGER,
    diskMb INTEGER,
    email VARCHAR(255),
    accumulatedRewardAmount NUMERIC(30, 10),
    uriTokenId VARCHAR(255),
    countryCode VARCHAR(10),
    description TEXT,
    registrationLedger BIGINT,
    registrationFee NUMERIC(30, 10),
    maxInstances INTEGER,
    activeInstances INTEGER,
    lastHeartbeatIndex BIGINT,
    version VARCHAR(50),
    isATransferer BOOLEAN,
    lastVoteCandidateIdx INTEGER,
    lastVoteTimestamp BIGINT,
    supportVoteSent BOOLEAN,
    registrationTimestamp BIGINT,
    hostReputation NUMERIC(10, 6),
    reputedOnHeartbeat BOOLEAN,
    transferTimestamp BIGINT,
    leaseAmount NUMERIC(30, 10),
    active BOOLEAN,
    domain VARCHAR(255),
    domainTLD VARCHAR(50),
    hostRating NUMERIC(10, 6),
    hostRatingStr VARCHAR(10),
    scoreMoment BIGINT,
    scoreNumerator NUMERIC(30, 10),
    scoreDenominator NUMERIC(30, 10),
    score NUMERIC(30, 20),
    score100 NUMERIC(10, 6),
    score255 INTEGER,
    scoreLastResetMoment BIGINT,
    scoreLastScoredMoment BIGINT,
    scoreLastUniverseSize INTEGER,
    scoreValid BOOLEAN,
    execution_ts TIMESTAMP NOT NULL         -- Timestamp of data collection batch
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_evernode_address ON evernode_hosts(address);
CREATE INDEX IF NOT EXISTS idx_evernode_domain ON evernode_hosts(domain);
CREATE INDEX IF NOT EXISTS idx_evernode_execution_ts ON evernode_hosts(execution_ts DESC);
CREATE INDEX IF NOT EXISTS idx_evernode_active ON evernode_hosts(active);
CREATE INDEX IF NOT EXISTS idx_evernode_country ON evernode_hosts(countryCode);
CREATE INDEX IF NOT EXISTS idx_evernode_composite ON evernode_hosts(address, execution_ts DESC);

-- Create view for latest host data
CREATE OR REPLACE VIEW latest_evernode_hosts AS
SELECT DISTINCT ON (address)
    id,
    key,
    addressKey,
    address,
    cpuModelName,
    cpuCount,
    cpuMHz,
    cpuMicrosec,
    ramMb,
    diskMb,
    email,
    accumulatedRewardAmount,
    uriTokenId,
    countryCode,
    description,
    registrationLedger,
    registrationFee,
    maxInstances,
    activeInstances,
    lastHeartbeatIndex,
    version,
    isATransferer,
    lastVoteCandidateIdx,
    lastVoteTimestamp,
    supportVoteSent,
    registrationTimestamp,
    hostReputation,
    reputedOnHeartbeat,
    transferTimestamp,
    leaseAmount,
    active,
    domain,
    domainTLD,
    hostRating,
    hostRatingStr,
    scoreMoment,
    scoreNumerator,
    scoreDenominator,
    score,
    score100,
    score255,
    scoreLastResetMoment,
    scoreLastScoredMoment,
    scoreLastUniverseSize,
    scoreValid,
    execution_ts
FROM evernode_hosts
ORDER BY address, execution_ts DESC;

-- Create view for host statistics summary
CREATE OR REPLACE VIEW evernode_summary AS
SELECT 
    COUNT(*) as total_hosts,
    COUNT(*) FILTER (WHERE active = true) as active_hosts,
    COUNT(*) FILTER (WHERE active = false) as inactive_hosts,
    AVG(cpuCount) as avg_cpu_count,
    AVG(ramMb) as avg_ram_mb,
    AVG(diskMb) as avg_disk_mb,
    AVG(hostReputation) as avg_reputation,
    AVG(activeInstances) as avg_active_instances,
    MAX(execution_ts) as last_updated
FROM latest_evernode_hosts;

-- Create view for hosts by country
CREATE OR REPLACE VIEW evernode_by_country AS
SELECT 
    countryCode,
    COUNT(*) as host_count,
    COUNT(*) FILTER (WHERE active = true) as active_count,
    AVG(hostReputation) as avg_reputation,
    SUM(activeInstances) as total_active_instances
FROM latest_evernode_hosts
GROUP BY countryCode
ORDER BY host_count DESC;

COMMENT ON TABLE evernode_hosts IS 'Stores Evernode network host statistics with historical snapshots';
COMMENT ON COLUMN evernode_hosts.execution_ts IS 'Timestamp when this batch of data was collected';
COMMENT ON VIEW latest_evernode_hosts IS 'Shows the most recent data for each host';
COMMENT ON VIEW evernode_summary IS 'Provides aggregate statistics across all hosts';
COMMENT ON VIEW evernode_by_country IS 'Summarizes host distribution and stats by country';