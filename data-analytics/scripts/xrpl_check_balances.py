from xrpl.clients import JsonRpcClient
from xrpl.models import AccountLines, AccountInfo
from xrpl.account import get_balance
import psycopg2
import time
import random
from datetime import datetime, timezone
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, BlockchainConfig, Colors
from utils import decode_currency_code, safe_hex_to_str, make_request_with_retry

# Load configuration
DB_CONFIG = DatabaseConfig.get_db_config(DatabaseConfig.ASSET_BALANCES)
accounts = BlockchainConfig.get_xrpl_accounts()
client = JsonRpcClient(BlockchainConfig.XRPL_RPC_URL)

def insert_balance(conn, source, account, name, asset_type, balance, domain, ts):
    """Insert balance data into PostgreSQL"""
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO asset_balances
                (source, account, name, asset_type, balance, domain, ts)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (source, account, name, asset_type, balance, domain, ts))
        conn.commit()
    except psycopg2.Error as e:
        print(f"Database error: {str(e)}")
        conn.rollback()

def process_account(conn, account):
    """Process a single account with rate limit handling"""
    address = account["address"]
    name = account["name"]
    ts = datetime.now(timezone.utc)
    domain = None

    try:
        # Get validated XRP balance using official method
        xrp_balance = get_balance(address, client) / 1_000_000
        print(f" XRP Balance: {xrp_balance}")
        insert_balance(conn, 'xrpl', address, name, 'XRP', xrp_balance, domain, ts)

        # Get account info for domain
        info_response = make_request_with_retry(
            lambda: client.request(AccountInfo(
                account=address,
                ledger_index="validated"
            ))
        )
        account_data = info_response.result.get("account_data", {})
        domain_hex = account_data.get("Domain")
        domain = safe_hex_to_str(domain_hex) if domain_hex else None

        # Get token balances with currency code decoding
        lines_response = make_request_with_retry(
            lambda: client.request(AccountLines(
                account=address,
                ledger_index="validated"
            ))
        )
        time.sleep(1)

        if lines_response.result.get("lines"):
            for line in lines_response.result["lines"]:
                raw_token = line['currency']
                token = decode_currency_code(raw_token)
                balance = float(line['balance'])
                print(f" Token: {token} ({raw_token}), Balance: {balance}")
                insert_balance(conn, 'xrpl', address, name, token, balance, domain, ts)

    except Exception as e:
        print(f"❌ Error processing {name}: {str(e)}")

def main():
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            print(f"Loaded {len(accounts)} accounts.")
            random.shuffle(accounts)
            for index, account in enumerate(accounts):
                print(f"{index+1}/{len(accounts)} {Colors.CYAN}{account['name']}{Colors.RESET} ({account['address']})")
                process_account(conn, account)
                print(f"⏳ Adding inter-account delay")
                time.sleep(random.uniform(4, 8))
                print("-" * 40)
    except psycopg2.OperationalError as e:
        print(f"Failed to connect to database: {str(e)}")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    main()

