import websockets
import asyncio
import psycopg2
from datetime import datetime
import sys
import os
import logging

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import DatabaseConfig, ISSConfig, Colors

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def connect_to_iss():
    """
    Connect to ISS Lightstreamer feed and collect telemetry data.
    
    This is an experimental feature for collecting real-time data from the
    International Space Station via NASA's public Lightstreamer API.
    """
    db_config = DatabaseConfig.get_db_config(DatabaseConfig.ISS_METRICS)
    conn = None
    
    try:
        # Connect to database
        conn = psycopg2.connect(**db_config)
        logger.info(f"{Colors.GREEN}Connected to ISS metrics database{Colors.RESET}")
        
        # Connect to ISS Lightstreamer WebSocket
        logger.info(f"{Colors.YELLOW}Connecting to ISS Lightstreamer: {ISSConfig.LS_URL}{Colors.RESET}")
        
        async with websockets.connect(ISSConfig.LS_URL) as ws:
            # Send authentication
            auth_msg = f"LS_user={ISSConfig.LS_USER}&LS_password={ISSConfig.LS_PASSWORD}&LS_adapter_set={ISSConfig.LS_ADAPTER}"
            await ws.send(auth_msg)
            logger.info(f"{Colors.GREEN}✓ Authenticated with Lightstreamer{Colors.RESET}")
            
            # Subscribe to telemetry stream
            # Note: The actual subscription message may need adjustment based on NASA's API
            subscribe_msg = "LS_mode=MERGE&LS_items=URINE_TANK_LEVEL&LS_fields=Value TimeStamp"
            await ws.send(subscribe_msg)
            logger.info(f"{Colors.CYAN}Subscribed to ISS telemetry stream{Colors.RESET}")
            
            message_count = 0
            
            # Receive and process messages
            while True:
                try:
                    response = await asyncio.wait_for(ws.recv(), timeout=30.0)
                    message_count += 1
                    
                    # Parse the response
                    # Format may vary - this is a simple parser
                    if "URINE_TANK_LEVEL" in response or "|" in response:
                        parts = response.split("|")
                        
                        # Try to extract numeric value
                        for part in parts:
                            try:
                                tank_level = float(part)
                                timestamp = datetime.now()
                                
                                # Insert into database
                                with conn.cursor() as cur:
                                    cur.execute("""
                                        INSERT INTO telemetry (timestamp, level, metric_name, raw_data)
                                        VALUES (%s, %s, %s, %s)
                                    """, (timestamp, tank_level, 'URINE_TANK_LEVEL', response[:500]))
                                    conn.commit()
                                
                                logger.info(f"{Colors.GREEN}✓ Recorded: Tank Level = {tank_level}% at {timestamp}{Colors.RESET}")
                                break
                            except ValueError:
                                continue
                    
                    # Log progress every 10 messages
                    if message_count % 10 == 0:
                        logger.info(f"{Colors.CYAN}Processed {message_count} messages{Colors.RESET}")
                
                except asyncio.TimeoutError:
                    logger.warning(f"{Colors.YELLOW}⚠️  No data received for 30 seconds, checking connection...{Colors.RESET}")
                    # Send ping to keep connection alive
                    await ws.ping()
                
                except Exception as e:
                    logger.error(f"{Colors.RED}Error processing message: {str(e)}{Colors.RESET}")
                    continue
    
    except websockets.exceptions.WebSocketException as e:
        logger.error(f"{Colors.RED}WebSocket error: {str(e)}{Colors.RESET}")
        logger.info("Note: This is an experimental feature. The ISS Lightstreamer API may require specific authentication or have changed.")
    
    except psycopg2.Error as e:
        logger.error(f"{Colors.RED}Database error: {str(e)}{Colors.RESET}")
    
    except KeyboardInterrupt:
        logger.info(f"\n{Colors.YELLOW}Shutting down ISS collector...{Colors.RESET}")
    
    except Exception as e:
        logger.error(f"{Colors.RED}Unexpected error: {str(e)}{Colors.RESET}")
    
    finally:
        if conn:
            conn.close()
            logger.info(f"{Colors.GREEN}Database connection closed{Colors.RESET}")

def main():
    """Main entry point"""
    logger.info(f"{Colors.CYAN}{'='*50}{Colors.RESET}")
    logger.info(f"{Colors.CYAN}ISS Telemetry Collector (Experimental){Colors.RESET}")
    logger.info(f"{Colors.CYAN}{'='*50}{Colors.RESET}")
    logger.info("")
    logger.warning(f"{Colors.YELLOW}⚠️  This is an experimental feature.{Colors.RESET}")
    logger.warning(f"{Colors.YELLOW}The ISS Lightstreamer API may require updates or specific credentials.{Colors.RESET}")
    logger.info("")
    
    try:
        asyncio.run(connect_to_iss())
    except KeyboardInterrupt:
        logger.info(f"\n{Colors.GREEN}Exited cleanly{Colors.RESET}")

if __name__ == "__main__":
    main()

