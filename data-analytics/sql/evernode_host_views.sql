-- Enhanced Views for Evernode Host Stats
-- Run on evernode_host_stats database

-- Latest Evernode host stats
CREATE OR REPLACE VIEW latest_evernode_stats AS
SELECT DISTINCT ON (domain)
    domain,
    active,
    cpucount,
    rammb,
    diskmb,
    hostreputation,
    activeinstances,
    maxinstances,
    accumulatedrewardamount,
    leaseamount,
    countrycode,
    version,
    execution_ts
FROM evernode_hosts
WHERE domain LIKE '%baggerzzz%'
ORDER BY domain, execution_ts DESC;

-- Host utilization metrics
CREATE OR REPLACE VIEW evernode_host_utilization AS
SELECT 
    domain,
    active,
    ROUND((activeinstances::numeric / NULLIF(maxinstances, 0)::numeric * 100), 2) as utilization_pct,
    activeinstances,
    maxinstances,
    maxinstances - activeinstances as available_instances,
    hostreputation,
    execution_ts
FROM latest_evernode_stats
ORDER BY domain;

-- Host reputation trends
CREATE OR REPLACE VIEW evernode_reputation_history AS
SELECT 
    execution_ts as timestamp,
    domain,
    hostreputation,
    activeinstances
FROM evernode_hosts
WHERE domain LIKE '%baggerzzz%'
    AND execution_ts > NOW() - INTERVAL '30 days'
ORDER BY execution_ts DESC;

-- Evernode summary statistics
CREATE OR REPLACE VIEW evernode_summary AS
SELECT 
    COUNT(*) as total_hosts,
    COUNT(*) FILTER (WHERE active = true) as active_hosts,
    SUM(activeinstances) as total_active_instances,
    SUM(maxinstances) as total_max_instances,
    ROUND(AVG(hostreputation), 0) as avg_reputation,
    ROUND((SUM(activeinstances)::numeric / NULLIF(SUM(maxinstances), 0)::numeric * 100), 2) as overall_utilization_pct,
    SUM(accumulatedrewardamount) as total_rewards
FROM latest_evernode_stats;

-- Host comparison table
CREATE OR REPLACE VIEW evernode_host_comparison AS
SELECT 
    domain,
    cpucount as cpu,
    ROUND(rammb::numeric / 1024, 1) as ram_gb,
    ROUND(diskmb::numeric / 1024, 1) as disk_gb,
    hostreputation as reputation,
    activeinstances || '/' || maxinstances as instances,
    CASE WHEN active THEN '✓ Online' ELSE '✗ Offline' END as status,
    ROUND(accumulatedrewardamount, 2) as rewards
FROM latest_evernode_stats
ORDER BY hostreputation DESC, domain;

-- Instance utilization over time
CREATE OR REPLACE VIEW evernode_utilization_history AS
SELECT 
    execution_ts as timestamp,
    domain,
    activeinstances,
    maxinstances,
    ROUND((activeinstances::numeric / NULLIF(maxinstances, 0)::numeric * 100), 2) as utilization_pct
FROM evernode_hosts
WHERE domain LIKE '%baggerzzz%'
    AND execution_ts > NOW() - INTERVAL '30 days'
ORDER BY execution_ts DESC;

COMMENT ON VIEW latest_evernode_stats IS 'Current stats for all monitored Evernode hosts';
COMMENT ON VIEW evernode_host_utilization IS 'Instance utilization metrics per host';
COMMENT ON VIEW evernode_reputation_history IS 'Historical reputation tracking over 30 days';
COMMENT ON VIEW evernode_summary IS 'Aggregate statistics across all hosts';
COMMENT ON VIEW evernode_host_comparison IS 'Side-by-side host comparison table';
COMMENT ON VIEW evernode_utilization_history IS 'Historical instance utilization trends';