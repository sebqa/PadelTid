from fastapi import APIRouter, HTTPException, Query
from services.padel_service import PadelService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
padel_service = PadelService()

@router.get("/padel-recommendations")
async def get_padel_recommendations(
    userId: str = Query(...),
    locations: str = Query(..., description="Comma-separated list of locations")
):
    """Get padel recommendations for a user"""
    try:
        locations_list = [loc.strip() for loc in locations.split(',') if loc.strip()]
        return await padel_service.get_recommendations(userId, locations_list)
    except Exception as e:
        logger.error(f"Error in get_padel_recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/document/{doc_id}")
async def get_document_by_id(doc_id: str):
    """Get document by ID - migrated from getDocumentById Lambda"""
    try:
        return await padel_service.get_document_by_id(doc_id)
    except Exception as e:
        logger.error(f"Error in get_document_by_id: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 