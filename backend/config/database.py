from pymongo import MongoClient
import stripe
import logging
from .settings import get_settings

logger = logging.getLogger(__name__)

# Global database connections
client = None
db_padel_times = None
db_padeltid = None
_database_initialized = False
_stripe_initialized = False
_database_error = None
_stripe_error = None

def init_database():
    """Initialize database connections and optionally Stripe"""
    global client, db_padel_times, db_padeltid, _database_initialized, _stripe_initialized, _database_error, _stripe_error
    
    try:
        settings = get_settings()
        
        # Check if required environment variables are set
        if not settings.atlas_uri:
            _database_error = "ATLAS_URI environment variable not set"
            logger.warning(_database_error)
            return False
        
        # Initialize MongoDB
        try:
            client = MongoClient(host=settings.atlas_uri)
            # Test the connection
            client.admin.command('ping')
            db_padel_times = client['padelTimes']
            db_padeltid = client['padeltid']
            logger.info("MongoDB connection initialized successfully")
            _database_initialized = True
        except Exception as e:
            _database_error = f"Failed to initialize MongoDB: {str(e)}"
            logger.error(_database_error)
            return False
        
        # Initialize Stripe (optional)
        if settings.stripe_secret_key:
            try:
                stripe.api_key = settings.stripe_secret_key
                logger.info("Stripe API initialized successfully")
                _stripe_initialized = True
            except Exception as e:
                _stripe_error = f"Failed to initialize Stripe: {str(e)}"
                logger.warning(_stripe_error)
                # Don't fail database init if Stripe fails
        else:
            logger.info("Stripe not configured - subscription features will be disabled")
            _stripe_error = "Stripe credentials not provided"
            
        _database_error = None
        return True
        
    except Exception as e:
        _database_error = f"Unexpected error during database initialization: {str(e)}"
        logger.error(_database_error)
        return False

def get_db_padel_times():
    """Get PadelTimes database"""
    if not _database_initialized:
        raise RuntimeError(f"Database not initialized: {_database_error}")
    return db_padel_times

def get_db_padeltid():
    """Get PadelTid database"""
    if not _database_initialized:
        raise RuntimeError(f"Database not initialized: {_database_error}")
    return db_padeltid

def is_database_ready():
    """Check if database is ready"""
    return _database_initialized

def is_stripe_ready():
    """Check if Stripe is ready"""
    return _stripe_initialized

def get_database_error():
    """Get database initialization error if any"""
    return _database_error

def get_stripe_error():
    """Get Stripe initialization error if any"""
    return _stripe_error 