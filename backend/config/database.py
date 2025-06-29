from pymongo import MongoClient
import stripe
import logging
from .settings import get_settings

logger = logging.getLogger(__name__)

# Global database connections
client = None
db_padel_times = None
db_padeltid = None

def init_database():
    """Initialize database connections and Stripe"""
    global client, db_padel_times, db_padeltid
    
    settings = get_settings()
    
    # Initialize MongoDB
    try:
        client = MongoClient(host=settings.atlas_uri)
        db_padel_times = client['padelTimes']
        db_padeltid = client['padeltid']
        logger.info("MongoDB connection initialized")
    except Exception as e:
        logger.error(f"Failed to initialize MongoDB: {str(e)}")
        raise
    
    # Initialize Stripe
    try:
        stripe.api_key = settings.stripe_secret_key
        logger.info("Stripe API initialized")
    except Exception as e:
        logger.error(f"Failed to initialize Stripe: {str(e)}")
        raise

def get_db_padel_times():
    """Get PadelTimes database"""
    if db_padel_times is None:
        raise RuntimeError("Database not initialized")
    return db_padel_times

def get_db_padeltid():
    """Get PadelTid database"""
    if db_padeltid is None:
        raise RuntimeError("Database not initialized")
    return db_padeltid 