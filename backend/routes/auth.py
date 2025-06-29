from fastapi import APIRouter, HTTPException, Request
from services.auth_service import AuthService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
auth_service = AuthService()

@router.post("/auth")
async def authenticate(request: Request):
    """Authenticate user - migrated from auth Lambda"""
    try:
        body = await request.json()
        return await auth_service.authenticate(body)
    except Exception as e:
        logger.error(f"Error in authenticate: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/manage-tokens")
async def manage_tokens(request: Request):
    """Manage user tokens - migrated from manageTokens Lambda"""
    try:
        body = await request.json()
        return await auth_service.manage_tokens(body)
    except Exception as e:
        logger.error(f"Error in manage_tokens: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 