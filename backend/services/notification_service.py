from config.database import get_db_padeltid
import logging

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self):
        self.db = get_db_padeltid
    
    async def send_notification(self, data: dict):
        """Send notification"""
        try:
            # TODO: Implement logic from sendNotification Lambda function
            return {
                "message": "Notification endpoint - implement from sendNotification Lambda",
                "data": data
            }
        except Exception as e:
            logger.error(f"Error in send_notification: {str(e)}")
            raise e
    
    async def subscribe_to_topic(self, data: dict):
        """Subscribe to topic"""
        try:
            # TODO: Implement logic from subTopic Lambda function
            return {
                "message": "Subscribe to topic endpoint - implement from subTopic Lambda",
                "data": data
            }
        except Exception as e:
            logger.error(f"Error in subscribe_to_topic: {str(e)}")
            raise e 