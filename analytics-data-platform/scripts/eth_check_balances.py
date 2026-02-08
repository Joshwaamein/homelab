from web3 import Web3
from pycoingecko import CoinGeckoAPI
import psycopg2
import requests
import time
import random
from datetime import datetime, timezone
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, BlockchainConfig, APIKeys, Colors

class EthereumBalanceIntegration:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(BlockchainConfig.WEB3_PROVIDER_URL))
        self.cg = CoinGeckoAPI()
        self.execution_id = int(datetime.utcnow().strftime('%Y%m%d%H%M%S'))
        self.db_config = DatabaseConfig.get_db_config(DatabaseConfig.ASSET_BALANCES)
    
    def get_all_tokens(self, address: str) -> list:
        """Get ERC20 tokens with balance >0 using Moralis"""
        url = f"https://deep-index.moralis.io/api/v2.2/{address}/erc20"
        headers = {"X-API-Key": APIKeys.MORALIS}
        
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            return [t for t in response.json() if float(t['balance']) > 0]
        except Exception as e:
            print(f"⚠️ Token fetch error: {str(e)}")
            return []

    def get_eth_balance(self, address: str) -> float:
        """Get ETH balance in ether"""
        return self.web3.from_wei(self.web3.eth.get_balance(address), 'ether')

    def insert_balance(self, conn, account_data: dict, asset_type: str, 
                      balance: float, usd_price: float):
        """Insert into asset_balances table"""
        ts = datetime.now(timezone.utc)
        usd_value = balance * usd_price if usd_price else None

        try:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO asset_balances 
                    (source, account, name, asset_type, balance, 
                     usd_price, usd_value, domain, ts, execution_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    'ethereum',
                    account_data['address'],
                    account_data.get('name', ''),
                    asset_type,
                    balance,
                    usd_price,
                    usd_value,
                    None,  # Domain not available on Ethereum
                    ts,
                    self.execution_id
                ))
            conn.commit()
        except Exception as e:
            print(f"Database error: {str(e)}")
            conn.rollback()

    def process_account(self, conn, account: dict):
        """Process an Ethereum account"""
        print(f"\n{Colors.CYAN}Processing {account.get('name', '')} ({account['address']}){Colors.RESET}")
        
        # Process ETH balance
        eth_balance = self.get_eth_balance(account['address'])
        eth_price = self.cg.get_price(ids='ethereum', vs_currencies='usd')['ethereum']['usd']
        print(f"  ETH: {eth_balance:.4f} (${eth_balance * eth_price:.2f})")
        self.insert_balance(conn, account, 'ETH', eth_balance, eth_price)
        
        # Process ERC20 tokens
        tokens = self.get_all_tokens(account['address'])
        print(f"  Found {len(tokens)} tokens with balance >0")
        
        for token in tokens:
            symbol = token.get('symbol', 'UNKNOWN').upper()
            decimals = int(token.get('decimals', 18))
            raw_balance = int(token.get('balance', 0))
            balance = raw_balance / (10 ** decimals)
            
            # Get USD price
            try:
                price = self.cg.get_price(ids=symbol.lower(), vs_currencies='usd').get(symbol.lower(), {}).get('usd')
            except Exception as e:
                print(f"⚠️ Price error for {symbol}: {str(e)}")
                price = None
            
            print(f"  {symbol}: {balance:.4f} (${(balance * price):.2f if price else 'N/A'})")
            self.insert_balance(conn, account, symbol, balance, price)
            time.sleep(random.uniform(0.3, 0.7))

    def run(self):
        """Main execution flow"""
        try:
            with psycopg2.connect(**self.db_config) as conn:
                print(f"\n{Colors.GREEN}Starting Ethereum Balance Integration{Colors.RESET}")
                
                # Load accounts from config
                accounts = BlockchainConfig.get_eth_accounts()
                if not accounts:
                    print(f"{Colors.YELLOW}No Ethereum accounts configured in .env{Colors.RESET}")
                    return
                
                random.shuffle(accounts)
                for account in accounts:
                    self.process_account(conn, account)
                    print(f"{Colors.YELLOW}Waiting for next account...{Colors.RESET}")
                    time.sleep(random.randint(4, 8))
                
                print(f"\n{Colors.GREEN}Completed run {self.execution_id}{Colors.RESET}")

        except Exception as e:
            print(f"🚨 Critical error: {str(e)}")

if __name__ == "__main__":
    monitor = EthereumBalanceIntegration()
    monitor.run()

