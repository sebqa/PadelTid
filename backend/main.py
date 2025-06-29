from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from routes import clubs, subscriptions, padel, weather, auth, notifications
from config.database import init_database, is_database_ready, is_stripe_ready, get_database_error, get_stripe_error
from config.settings import get_settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize settings
settings = get_settings()

# Initialize FastAPI app
app = FastAPI(
    title="PadelTid API", 
    version="1.0.2",  # Updated for Railway configuration fix
    description="Consolidated PadelTid API - migrated from AWS Lambda"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database connections (don't crash if it fails)
logger.info("Initializing database connections...")
db_success = init_database()
if db_success:
    logger.info("Database initialization successful")
    if is_stripe_ready():
        logger.info("Stripe is configured - subscription features available")
    else:
        logger.info("Stripe not configured - subscription features disabled")
else:
    logger.warning("Database initialization failed - API will start but database features may not work")

# Include routers
app.include_router(clubs.router, prefix="/api", tags=["clubs"])
app.include_router(subscriptions.router, prefix="/api", tags=["subscriptions"])
app.include_router(padel.router, prefix="/api", tags=["padel"])
app.include_router(weather.router, prefix="/api", tags=["weather"])
app.include_router(auth.router, prefix="/api", tags=["auth"])
app.include_router(notifications.router, prefix="/api", tags=["notifications"])

# Health check endpoint
@app.get("/")
async def health_check():
    """Simple health check that always works"""
    return {
        "status": "healthy", 
        "message": "PadelTid API is running",
        "version": "1.0.0"
    }

@app.get("/health")
async def detailed_health():
    """Detailed health check with database and Stripe status"""
    db_ready = is_database_ready()
    stripe_ready = is_stripe_ready()
    db_error = get_database_error()
    stripe_error = get_stripe_error()
    
    return {
        "status": "healthy",
        "api": "running",
        "database": "connected" if db_ready else "disconnected",
        "database_error": db_error if not db_ready else None,
        "stripe": "configured" if stripe_ready else "not_configured",
        "stripe_error": stripe_error if not stripe_ready else None,
        "features": {
            "clubs": db_ready,
            "padel_recommendations": db_ready,
            "weather_updates": db_ready,
            "subscriptions": db_ready and stripe_ready,
            "authentication": db_ready,
            "notifications": db_ready
        },
        "version": "1.0.0"
    }

@app.get("/readiness")
async def readiness_check():
    """Readiness check for Kubernetes/Railway - only requires database"""
    db_ready = is_database_ready()
    
    if db_ready:
        return {
            "status": "ready", 
            "database": "connected",
            "stripe": "configured" if is_stripe_ready() else "optional"
        }
    else:
        return {
            "status": "not_ready", 
            "database": "disconnected",
            "error": get_database_error()
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.port) 