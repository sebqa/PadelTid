from fastapi import APIRouter, HTTPException, Query
from services.padel_service import PadelService
import logging
from typing import Optional

logger = logging.getLogger(__name__)

router = APIRouter()
padel_service = PadelService()

@router.get("/padel-times")
async def get_padel_times(
    wind_speed_threshold: float = Query(..., description="Wind speed threshold (m/s)"),
    precipitation_probability_threshold: float = Query(..., description="Precipitation probability threshold (%)"),
    temperature_threshold: float = Query(..., description="Temperature threshold (°C)"),
    showUnavailableSlots: str = Query(..., description="Show unavailable slots (true/false)"),
    locations: str = Query(default="", description="Comma-separated list of locations"),
    user_id: Optional[str] = Query(default=None, description="User ID for follow status"),
    recommendation: str = Query(default="false", description="Get recommendations only (true/false)"),
    fetch_both: str = Query(default="false", description="Fetch both filtered and recommended (true/false)"),
    notify_on_matching_courts: str = Query(default="false", description="Enable notifications"),
    notification_wind_threshold: Optional[float] = Query(default=None, description="Notification wind threshold"),
    notification_precipitation_threshold: Optional[float] = Query(default=None, description="Notification precipitation threshold"),
    notification_temperature_threshold: Optional[float] = Query(default=None, description="Notification temperature threshold"),
    notification_show_unavailable_courts: str = Query(default="false", description="Show unavailable courts in notifications"),
    court_type: str = Query(default="both", description="Court type filter (indoor/outdoor/both)")
):
    """
    Get padel times - matches the original getPadelTid Lambda function
    Supports multiple modes: filtered documents, recommendations only, or both
    """
    try:
        # Parse boolean parameters
        show_unavailable_slots = showUnavailableSlots.lower() == "true"
        is_recommendation_request = recommendation.lower() == "true"
        is_fetch_both = fetch_both.lower() == "true"
        
        # Parse locations
        locations_list = [loc.strip() for loc in locations.split(',') if loc.strip()] if locations else []
        
        # Save user preferences if user_id is provided
        if user_id:
            preferences = {
                "locations": locations_list,
                "notifyOnMatchingCourts": notify_on_matching_courts.lower() == "true"
            }
            
            # Add notification-specific thresholds if provided
            if notify_on_matching_courts.lower() == "true":
                if notification_wind_threshold is not None:
                    preferences["notification_wind_threshold"] = notification_wind_threshold
                if notification_precipitation_threshold is not None:
                    preferences["notification_precipitation_threshold"] = notification_precipitation_threshold
                if notification_temperature_threshold is not None:
                    preferences["notification_temperature_threshold"] = notification_temperature_threshold
                if notification_show_unavailable_courts:
                    preferences["notification_show_unavailable_courts"] = notification_show_unavailable_courts.lower() == "true"
            
            padel_service.save_user_preferences(user_id, preferences)
        
        # Handle combined request (fetch both filtered and recommended)
        if is_fetch_both:
            # Get regular filtered documents
            filtered_results = await padel_service.get_filtered_documents(
                wind_speed_threshold, 
                precipitation_probability_threshold,
                temperature_threshold,
                show_unavailable_slots,
                locations_list,
                user_id,
                court_type
            )
            
            # Get recommended documents
            recommended_results = []
            if user_id:
                recommended_results = await padel_service.get_recommendations(user_id, locations_list, court_type)
            
            # Return both in the response
            return {
                "filtered": filtered_results,
                "recommended": recommended_results
            }
        
        # Handle recommendation request only
        if is_recommendation_request:
            if not user_id:
                raise HTTPException(status_code=400, detail="user_id is required for recommendation requests")
                
            if not locations_list:
                raise HTTPException(status_code=400, detail="locations is required for recommendation requests")
                
            return await padel_service.get_recommendations(user_id, locations_list, court_type)
        
        # Default case: get filtered documents
        return await padel_service.get_filtered_documents(
            wind_speed_threshold, 
            precipitation_probability_threshold,
            temperature_threshold,
            show_unavailable_slots,
            locations_list,
            user_id,
            court_type
        )
        
    except Exception as e:
        logger.error(f"Error in get_padel_times: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/padel-recommendations")
async def get_padel_recommendations(
    userId: str = Query(...),
    locations: str = Query(..., description="Comma-separated list of locations")
):
    """Get padel recommendations for a user - simplified endpoint for backward compatibility"""
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