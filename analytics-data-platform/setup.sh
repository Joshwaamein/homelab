#!/bin/bash
# Database Setup Script for Data Collection System
# This script creates all required databases and tables

set -e  # Exit on error

echo "================================================"
echo "Data Collection System - Database Setup"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load configuration from .env
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please copy .env.example to .env and configure it first."
    exit 1
fi

# Source .env file
export $(grep -v '^#' .env | xargs)

DB_USER=${DB_USER:-root}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo -e "${YELLOW}Database Configuration:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  User: $DB_USER"
echo ""

# Function to create database if it doesn't exist
create_database() {
    local dbname=$1
    echo -e "${YELLOW}Checking database: ${dbname}${NC}"
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $dbname; then
        echo -e "${GREEN}✓ Database '$dbname' already exists${NC}"
    else
        echo -e "${YELLOW}Creating database: ${dbname}${NC}"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $dbname;"
        echo -e "${GREEN}✓ Database '$dbname' created${NC}"
    fi
    echo ""
}

# Function to execute SQL file
execute_sql() {
    local dbname=$1
    local sqlfile=$2
    echo -e "${YELLOW}Executing: ${sqlfile} on ${dbname}${NC}"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $dbname -f $sqlfile
    echo -e "${GREEN}✓ SQL executed successfully${NC}"
    echo ""
}

# Create all databases
echo -e "${YELLOW}=== Creating Databases ===${NC}"
create_database "${DB_ASSET_BALANCES:-asset_balances}"
create_database "${DB_ENVIRONMENT_METRICS:-environment_metrics}"
create_database "${DB_EVERNODE_HOST_STATS:-evernode_host_stats}"
create_database "${DB_ISS_METRICS:-iss_metrics}"

# Create tables
echo -e "${YELLOW}=== Creating Tables ===${NC}"

# asset_balances schema
echo -e "${YELLOW}Creating asset_balances tables...${NC}"
execute_sql "${DB_ASSET_BALANCES:-asset_balances}" "sql/asset_balances.sql"

# environment_metrics schema
echo -e "${YELLOW}Creating environment_metrics tables...${NC}"
execute_sql "${DB_ENVIRONMENT_METRICS:-environment_metrics}" "sql/environment_metrics.sql"

# evernode_host_stats schema
echo -e "${YELLOW}Creating evernode_host_stats tables...${NC}"
execute_sql "${DB_EVERNODE_HOST_STATS:-evernode_host_stats}" "sql/evernode_host_stats.sql"

# iss_metrics schema
echo -e "${YELLOW}Creating iss_metrics tables...${NC}"
execute_sql "${DB_ISS_METRICS:-iss_metrics}" "sql/iss_metrics.sql"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Database setup completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify your .env configuration"
echo "2. Run: pip install -r requirements.txt"
echo "3. Test scripts: python scripts/xrpl_check_balances.py"
echo "4. Set up cron jobs (see README.md)"
echo ""