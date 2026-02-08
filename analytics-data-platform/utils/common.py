"""
Common utility functions shared across data collection scripts
"""
import time
import random
from binascii import Error as BinasciiError
from pycoingecko import CoinGeckoAPI
from config import ASSET_MAP

# Initialize CoinGecko client
cg = CoinGeckoAPI()


class ttl_cache:
    """Custom TTL cache with LRU eviction for price data"""
    def __init__(self, maxsize=128, ttl=300):
        self.maxsize = maxsize
        self.ttl = ttl
        self.cache = {}

    def __call__(self, func):
        def wrapped_func(arg):
            now = time.time()
            if arg in self.cache:
                value, timestamp = self.cache[arg]
                if now - timestamp < self.ttl:
                    return value
            value = func(arg)
            if len(self.cache) >= self.maxsize:
                oldest_key = min(self.cache, key=lambda k: self.cache[k][1])
                del self.cache[oldest_key]
            self.cache[arg] = (value, now)
            return value
        return wrapped_func


@ttl_cache(maxsize=10, ttl=300)  # Cache 10 prices for 5 minutes
def get_usd_price(asset_symbol):
    """
    Get USD price from CoinGecko with caching and TTL
    
    Args:
        asset_symbol: Asset symbol (e.g., 'XAH', 'EVR', 'XRP')
        
    Returns:
        float: USD price or None if not found
    """
    coin_id = ASSET_MAP.get(asset_symbol.upper())
    if not coin_id:
        return None
    
    for _ in range(3):
        try:
            price_data = cg.get_price(ids=coin_id, vs_currencies='usd')
            return price_data.get(coin_id, {}).get('usd')
        except Exception as e:
            print(f"⚠️ Price check error for {asset_symbol}: {str(e)}")
            time.sleep(random.uniform(10, 14))
    return None


def make_request_with_retry(request_func, max_retries=5, initial_delay=1):
    """
    Handle API rate limits with exponential backoff
    
    Args:
        request_func: Callable function that makes the API request
        max_retries: Maximum number of retry attempts
        initial_delay: Initial delay in seconds (doubles with each retry)
        
    Returns:
        API response
        
    Raises:
        Exception: If max retries exceeded
    """
    for attempt in range(max_retries):
        try:
            return request_func()
        except Exception as e:
            if 'rate limit' in str(e).lower() or 'too many' in str(e).lower():
                delay = initial_delay * (2 ** attempt) + random.uniform(0, 1)
                print(f"⚠️ Rate limited. Retry {attempt+1}/{max_retries} in {delay:.1f}s")
                time.sleep(delay)
            else:
                raise
    raise Exception("🚨 Max retries exceeded")


def safe_hex_to_str(hex_str):
    """
    Convert hex to string with error handling
    
    Args:
        hex_str: Hexadecimal string to decode
        
    Returns:
        str: Decoded string or None if decoding fails
    """
    try:
        return bytes.fromhex(hex_str).decode('utf-8')
    except (BinasciiError, UnicodeDecodeError, TypeError):
        return None


def decode_currency_code(hex_str):
    """
    Decode XRPL currency code to human-readable format
    
    XRPL uses 40-character hex strings for currency codes.
    Standard 3-letter codes (like USD) are padded with zeros.
    
    Args:
        hex_str: 40-character hex currency code
        
    Returns:
        str: Decoded currency code or original hex if decoding fails
    """
    try:
        if len(hex_str) != 40:
            return hex_str

        # Check if it's a standard 3-letter currency code (starts with 00)
        if hex_str[:2] == '00':
            chars = bytes.fromhex(hex_str[2:8]).decode('ascii', errors='ignore')
            return chars if len(chars) == 3 else hex_str

        # Try to decode non-standard currency codes
        decoded = bytes.fromhex(hex_str).decode('utf-8', errors='ignore')
        cleaned = decoded.replace('\x00', '')
        return cleaned if cleaned else hex_str
    except Exception:
        return hex_str