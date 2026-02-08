import requests
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import APIKeys, PolygonConfig

ALCHEMY_API_KEY = APIKeys.ALCHEMY
WALLET_ADDRESS = PolygonConfig.WALLET_ADDRESS

def get_token_balances_with_prices():
    # Get token balances
    balance_url = f"https://polygon-mainnet.g.alchemy.com/v2/{ALCHEMY_API_KEY}"
    balance_payload = {
        "jsonrpc": "2.0",
        "method": "alchemy_getTokenBalances",
        "params": [WALLET_ADDRESS, "erc20"],
        "id": 1
    }
    balance_response = requests.post(balance_url, json=balance_payload)
    tokens = balance_response.json().get("result", {}).get("tokenBalances", [])
    
    token_data = []
    for token in tokens:
        contract = token["contractAddress"]
        balance_hex = token["tokenBalance"]
        
        if int(balance_hex, 16) == 0:
            continue
            
        # Get token metadata
        metadata_payload = {
            "jsonrpc": "2.0",
            "method": "alchemy_getTokenMetadata",
            "params": [contract],
            "id": 1
        }
        metadata_response = requests.post(balance_url, json=metadata_payload)
        metadata = metadata_response.json().get("result", {})
        
        decimals = int(metadata.get("decimals", 18))
        formatted_balance = int(balance_hex, 16) / (10 ** decimals)
        
        # Get USD price
        price_payload = {
            "jsonrpc": "2.0",
            "method": "alchemy_getTokenPrice",
            "params": [{
                "contractAddress": contract,
                "chain": "polygon"  # Specify Polygon chain
            }],
            "id": 1
        }
        price_response = requests.post(balance_url, json=price_payload)
        price_data = price_response.json().get("result", {})
        usd_price = price_data.get("usdPrice", 0)
        
        token_data.append({
            "name": metadata.get("name", "Unknown"),
            "symbol": metadata.get("symbol", "UNKNOWN"),
            "balance": round(formatted_balance, 4),
            "usd_value": round(formatted_balance * usd_price, 2),
            "contract": contract
        })
    
    return token_data

# Print results
balances = get_token_balances_with_prices()
print(f"{'Token':<200} {'Symbol':<80} {'Balance':>150} {'USD Value':>150} {'Contract Address':<440}")
print("-" * 1005)
for token in balances:
    print(f"{token['name'][:200]:<200} {token['symbol']:<80} {token['balance']:>150,.40f} ${token['usd_value']:>140,.20f} {token['contract']}")
