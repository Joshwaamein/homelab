"""
Centralized configuration management for the data collection system.
Loads settings from environment variables via .env file.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Database Configuration
class DatabaseConfig:
    """Database connection settings"""
    HOST = os.getenv('DB_HOST', 'localhost')
    PORT = int(os.getenv('DB_PORT', 5432))
    USER = os.getenv('DB_USER', 'root')
    PASSWORD = os.getenv('DB_PASSWORD', '')
    
    # Database names
    ASSET_BALANCES = os.getenv('DB_ASSET_BALANCES', 'asset_balances')
    ENVIRONMENT_METRICS = os.getenv('DB_ENVIRONMENT_METRICS', 'environment_metrics')
    EVERNODE_HOST_STATS = os.getenv('DB_EVERNODE_HOST_STATS', 'evernode_host_stats')
    ISS_METRICS = os.getenv('DB_ISS_METRICS', 'iss_metrics')
    
    @staticmethod
    def get_db_config(dbname):
        """Get database configuration dictionary"""
        config = {
            "dbname": dbname,
            "user": DatabaseConfig.USER,
            "host": DatabaseConfig.HOST,
            "port": DatabaseConfig.PORT
        }
        if DatabaseConfig.PASSWORD:
            config["password"] = DatabaseConfig.PASSWORD
        return config


# API Keys
class APIKeys:
    """External API authentication"""
    MORALIS = os.getenv('MORALIS_API_KEY')
    ALCHEMY = os.getenv('ALCHEMY_API_KEY')


# Blockchain Configuration
class BlockchainConfig:
    """Blockchain RPC endpoints and account lists"""
    
    # RPC URLs
    XRPL_RPC_URL = os.getenv('XRPL_RPC_URL', 'https://s2.ripple.com:51234/')
    XAHAU_RPC_URL = os.getenv('XAHAU_RPC_URL', 'https://xahau.network')
    WEB3_PROVIDER_URL = os.getenv('WEB3_PROVIDER_URL')
    
    @staticmethod
    def parse_accounts(env_var_name):
        """Parse account list from environment variable
        
        Format: ADDRESS:NAME,ADDRESS:NAME,...
        Returns: [{"address": "...", "name": "..."}, ...]
        """
        accounts_str = os.getenv(env_var_name, '')
        if not accounts_str:
            return []
        
        accounts = []
        for pair in accounts_str.split(','):
            if ':' in pair:
                address, name = pair.split(':', 1)
                accounts.append({
                    "address": address.strip(),
                    "name": name.strip()
                })
        return accounts
    
    @staticmethod
    def get_xrpl_accounts():
        """Get XRPL account list"""
        return BlockchainConfig.parse_accounts('XRPL_ACCOUNTS')
    
    @staticmethod
    def get_xahau_accounts():
        """Get Xahau account list"""
        return BlockchainConfig.parse_accounts('XAHAU_ACCOUNTS')
    
    @staticmethod
    def get_eth_accounts():
        """Get Ethereum account list"""
        return BlockchainConfig.parse_accounts('ETH_ACCOUNTS')


# Evernode Configuration
class EvernodeConfig:
    """Evernode API settings"""
    API_URL = os.getenv('EVERNODE_API_URL', 'https://api.evernode.network/registry/hosts/baggerzzz.online')


# Raspberry Pi Configuration
class RaspberryPiConfig:
    """Raspberry Pi monitoring settings"""
    METRICS_URL = os.getenv('PI_METRICS_URL', 'http://ghost:5000/metrics')
    PING_TARGET = os.getenv('PI_PING_TARGET', 'ghost')


# Polygon Configuration
class PolygonConfig:
    """Polygon/Matic blockchain settings"""
    WALLET_ADDRESS = os.getenv('POLYGON_WALLET_ADDRESS')


# ISS Configuration (Experimental)
class ISSConfig:
    """International Space Station telemetry settings"""
    LS_URL = os.getenv('ISS_LS_URL', 'wss://lightstreamer.nasa.gov/WS')
    LS_ADAPTER = os.getenv('ISS_LS_ADAPTER', 'ISS_STREAM')
    LS_USER = os.getenv('ISS_LS_USER', 'USER')
    LS_PASSWORD = os.getenv('ISS_LS_PASSWORD', 'PASS')


# Asset Mapping for CoinGecko
ASSET_MAP = {
    "XAH": "xahau",
    "EVR": "evernode"
}


# ANSI Color Codes for Console Output
class Colors:
    """Terminal color codes"""
    CYAN = "\033[36m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"
    RESET = "\033[0m"


# Validate critical configuration on import
def validate_config():
    """Validate that critical configuration is present"""
    missing = []
    
    if not APIKeys.MORALIS:
        missing.append("MORALIS_API_KEY")
    
    if not APIKeys.ALCHEMY:
        missing.append("ALCHEMY_API_KEY")
    
    if missing:
        print(f"⚠️  Warning: Missing API keys in .env file: {', '.join(missing)}")
        print("   Some scripts may not function correctly.")


# Run validation on import
validate_config()