"""
Test script for basic functionality checks
This file can be used to test API connections and database connectivity
"""
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, Colors
import psycopg2
import requests


def test_database_connections():
    """Test connectivity to all configured databases"""
    print(f"\n{Colors.CYAN}{'='*50}{Colors.RESET}")
    print(f"{Colors.CYAN}Testing Database Connections{Colors.RESET}")
    print(f"{Colors.CYAN}{'='*50}{Colors.RESET}\n")
    
    databases = [
        ('Asset Balances', DatabaseConfig.ASSET_BALANCES),
        ('Environment Metrics', DatabaseConfig.ENVIRONMENT_METRICS),
        ('Evernode Host Stats', DatabaseConfig.EVERNODE_HOST_STATS),
        ('ISS Metrics', DatabaseConfig.ISS_METRICS)
    ]
    
    for name, dbname in databases:
        try:
            db_config = DatabaseConfig.get_db_config(dbname)
            conn = psycopg2.connect(**db_config)
            conn.close()
            print(f"{Colors.GREEN}✓ {name}: Connected successfully{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}✗ {name}: Failed - {str(e)}{Colors.RESET}")


def test_api_connectivity():
    """Test basic API connectivity"""
    print(f"\n{Colors.CYAN}{'='*50}{Colors.RESET}")
    print(f"{Colors.CYAN}Testing API Connectivity{Colors.RESET}")
    print(f"{Colors.CYAN}{'='*50}{Colors.RESET}\n")
    
    apis = [
        ('PokeAPI', 'https://pokeapi.co/api/v2/pokemon/ditto'),
        ('CoinGecko', 'https://api.coingecko.com/api/v3/ping'),
    ]
    
    for name, url in apis:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"{Colors.GREEN}✓ {name}: Reachable{Colors.RESET}")
            else:
                print(f"{Colors.YELLOW}⚠ {name}: Returned status {response.status_code}{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}✗ {name}: Failed - {str(e)}{Colors.RESET}")


def test_config_loading():
    """Test that configuration loads properly"""
    print(f"\n{Colors.CYAN}{'='*50}{Colors.RESET}")
    print(f"{Colors.CYAN}Testing Configuration Loading{Colors.RESET}")
    print(f"{Colors.CYAN}{'='*50}{Colors.RESET}\n")
    
    from config import BlockchainConfig, APIKeys, EvernodeConfig, RaspberryPiConfig
    
    print(f"XRPL Accounts: {len(BlockchainConfig.get_xrpl_accounts())} configured")
    print(f"Xahau Accounts: {len(BlockchainConfig.get_xahau_accounts())} configured")
    print(f"Ethereum Accounts: {len(BlockchainConfig.get_eth_accounts())} configured")
    print(f"Moralis API Key: {'✓ Set' if APIKeys.MORALIS else '✗ Missing'}")
    print(f"Alchemy API Key: {'✓ Set' if APIKeys.ALCHEMY else '✗ Missing'}")
    print(f"Evernode API: {EvernodeConfig.API_URL}")
    print(f"Pi Metrics URL: {RaspberryPiConfig.METRICS_URL}")
    print(f"Pi Ping Target: {RaspberryPiConfig.PING_TARGET}")


def main():
    """Run all tests"""
    print(f"\n{Colors.GREEN}{'='*60}{Colors.RESET}")
    print(f"{Colors.GREEN}Data Collection System - Test Suite{Colors.RESET}")
    print(f"{Colors.GREEN}{'='*60}{Colors.RESET}")
    
    test_config_loading()
    test_database_connections()
    test_api_connectivity()
    
    print(f"\n{Colors.GREEN}{'='*60}{Colors.RESET}")
    print(f"{Colors.GREEN}Test Suite Complete{Colors.RESET}")
    print(f"{Colors.GREEN}{'='*60}{Colors.RESET}\n")


if __name__ == "__main__":
    main()