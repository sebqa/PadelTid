from fastapi import APIRouter, HTTPException, Query, Request
from services.subscription_service import SubscriptionService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
subscription_service = SubscriptionService()

@router.get("/check-subscription")
async def check_subscription(userId: str = Query(...)):
    """Check subscription status for a user"""
    try:
        return await subscription_service.check_subscription(userId)
    except Exception as e:
        logger.error(f"Error in check_subscription: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/create-subscription")
async def create_subscription(request: Request):
    """Create a new subscription - migrated from createSubscription Lambda"""
    try:
        body = await request.json()
        return await subscription_service.create_subscription(body)
    except Exception as e:
        logger.error(f"Error in create_subscription: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/cancel-subscription")
async def cancel_subscription(request: Request):
    """Cancel a subscription - migrated from cancelSubscription Lambda"""
    try:
        body = await request.json()
        return await subscription_service.cancel_subscription(body)
    except Exception as e:
        logger.error(f"Error in cancel_subscription: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/invoices")
async def get_invoices(userId: str = Query(...)):
    """Get user invoices - migrated from getInvoices Lambda"""
    try:
        return await subscription_service.get_invoices(userId)
    except Exception as e:
        logger.error(f"Error in get_invoices: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 