from fastapi import APIRouter, HTTPException
from services.clubs_service import ClubsService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
clubs_service = ClubsService()

@router.get("/clubs")
async def get_clubs():
    """Get all clubs from the database"""
    try:
        return await clubs_service.get_all_clubs()
    except Exception as e:
        logger.error(f"Error in get_clubs: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/courts")
async def get_courts():
    """Get courts information - migrated from getCourts Lambda"""
    try:
        return await clubs_service.get_courts()
    except Exception as e:
        logger.error(f"Error in get_courts: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 