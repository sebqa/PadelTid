from fastapi import APIRouter, HTTPException
from services.weather_service import WeatherService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
weather_service = WeatherService()

@router.post("/update-weather")
async def update_weather():
    """Update weather data for all clubs"""
    try:
        result = await weather_service.update_all_weather()
        return {"message": "Weather data updated successfully", "result": result}
    except Exception as e:
        logger.error(f"Error updating weather: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/weather/{club_name}")
async def get_club_weather(club_name: str):
    """Get weather data for a specific club"""
    try:
        return await weather_service.get_club_weather(club_name)
    except Exception as e:
        logger.error(f"Error getting weather for {club_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 