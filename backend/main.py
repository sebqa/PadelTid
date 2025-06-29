from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from routes import clubs, subscriptions, padel, weather, auth, notifications
from config.database import init_database
from config.settings import get_settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize settings
settings = get_settings()

# Initialize FastAPI app
app = FastAPI(
    title="PadelTid API", 
    version="1.0.0",
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

# Initialize database connections
init_database()

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
    return {
        "status": "healthy", 
        "message": "PadelTid API is running",
        "version": "1.0.0"
    }

@app.get("/health")
async def detailed_health():
    return {
        "status": "healthy",
        "database": "connected",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.port) 