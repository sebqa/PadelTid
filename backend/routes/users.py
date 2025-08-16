from fastapi import APIRouter, HTTPException, Path
from pydantic import BaseModel, Field
from typing import Literal, Optional
from services.user_service import UserService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
user_service = UserService()

class UserProperties(BaseModel):
    skillLevel: float = Field(..., ge=1.0, le=7.0, description="Skill level between 1.0 and 7.0")
    courtSide: Literal['left', 'right', 'both'] = Field(..., description="Preferred court side")

class UserPropertiesResponse(BaseModel):
    skillLevel: Optional[float] = None
    courtSide: Optional[str] = None

@router.get("/users/{user_id}/properties", response_model=UserPropertiesResponse)
async def get_user_properties(user_id: str = Path(..., description="User ID")):
    """Get user properties (skillLevel and courtSide)"""
    try:
        return await user_service.get_user_properties(user_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error getting user properties for {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.put("/users/{user_id}/properties")
async def update_user_properties(
    user_id: str = Path(..., description="User ID"),
    properties: UserProperties = ...
):
    """Update user properties (skillLevel and courtSide)"""
    try:
        result = await user_service.update_user_properties(
            user_id, 
            properties.skillLevel, 
            properties.courtSide
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error updating user properties for {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")