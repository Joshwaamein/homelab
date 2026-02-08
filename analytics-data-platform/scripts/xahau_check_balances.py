from xahau.clients import JsonRpcClient
from xahau.models import AccountLines, AccountInfo
import psycopg2
import time
import random
from datetime import datetime, timezone
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, BlockchainConfig, Colors
from utils import safe_hex_to_str, make_request_with_retry, get_usd_price

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ASSET_BALANCES)
accounts = BlockchainConfig.get_xahau_accounts()
client = JsonRpcClient(BlockchainConfig.XAHAU_RPC_URL)

def insert_balance(conn, source, account, name, asset_type, balance, usd_price, usd_value, domain, ts, execution_id):
    """Insert balance data into PostgreSQL with execution_id."""
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO asset_balances 
                (source, account, name, asset_type, balance, usd_price, usd_value, domain, ts, execution_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (source, account, name, asset_type, balance, usd_price, usd_value, domain, ts, execution_id))
        conn.commit()
    except psycopg2.Error as e:
        print(f"Database error: {str(e)}")
        conn.rollback()

def process_account(conn, account, execution_id):
    """Process a single account with rate limit handling."""
    address = account["address"]
    name = account["name"]
    ts = datetime.now(timezone.utc)
    domain = None

    try:
        # Get AccountInfo with retry
        info_response = make_request_with_retry(
            lambda: client.request(AccountInfo(account=address))
        )
        time.sleep(1)

        # Extract domain and XAH balance
        account_data = info_response.result.get("account_data", {})
        domain_hex = account_data.get("Domain")
        domain = safe_hex_to_str(domain_hex) if domain_hex else None
        
        # Process XAH balance using cached price
        xah_balance = int(account_data.get("Balance", 0))
        xah_balance_xah = xah_balance / 1_000_000
        xah_price = get_usd_price("XAH")  # From cache
        xah_usd_value = xah_balance_xah * xah_price if xah_price is not None else None
        print(f"  XAH Balance: {xah_balance_xah} | USD Price: ${xah_price or 'N/A'}")
        insert_balance(conn, 'xahau', address, name, 'XAH', xah_balance_xah, xah_price, xah_usd_value, domain, ts, execution_id)

        # Get token balances
        lines_response = make_request_with_retry(
            lambda: client.request(AccountLines(account=address))
        )
        time.sleep(1)

        if lines_response.result.get("lines"):
            for line in lines_response.result["lines"]:
                token = line['currency']
                balance = float(line['balance'])
                token_price = get_usd_price(token)  # Uses cache for EVR
                token_usd_value = balance * token_price if token_price is not None else None
                print(f"  Token: {token}, Balance: {balance} | USD Price: ${token_price or 'N/A'}")
                insert_balance(conn, 'xahau', address, name, token, balance, token_price, token_usd_value, domain, ts, execution_id)

    except Exception as e:
        print(f"❌ Error processing {name}: {str(e)}")

def main():
    try:
        execution_id = int(datetime.utcnow().strftime('%Y%m%d%H%M%S'))
        
        # Pre-fetch prices to prime the cache
        xah_price = get_usd_price("XAH")
        evr_price = get_usd_price("EVR")
        
        with psycopg2.connect(**DB_CONFIG) as conn:
            print(f"Loaded {len(accounts)} accounts.")
            random.shuffle(accounts)
            for index, account in enumerate(accounts):
                print(f"{index+1}/{len(accounts)} {Colors.CYAN}{account['name']}{Colors.RESET} ({account['address']})")
                process_account(conn, account, execution_id)
                print(f"⏳ Adding inter-account delay")
                time.sleep(random.uniform(4, 8))
                print("-" * 40)
                
    except psycopg2.OperationalError as e:
        print(f"Failed to connect to database: {str(e)}")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    main()

