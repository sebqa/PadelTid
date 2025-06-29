from fastapi import APIRouter, HTTPException, Request
from services.notification_service import NotificationService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
notification_service = NotificationService()

@router.post("/send-notification")
async def send_notification(request: Request):
    """Send notification - migrated from sendNotification Lambda"""
    try:
        body = await request.json()
        return await notification_service.send_notification(body)
    except Exception as e:
        logger.error(f"Error in send_notification: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/subscribe-topic")
async def subscribe_to_topic(request: Request):
    """Subscribe to topic - migrated from subTopic Lambda"""
    try:
        body = await request.json()
        return await notification_service.subscribe_to_topic(body)
    except Exception as e:
        logger.error(f"Error in subscribe_to_topic: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 