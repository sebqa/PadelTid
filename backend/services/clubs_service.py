from config.database import get_db_padel_times
import logging

logger = logging.getLogger(__name__)

class ClubsService:
    def __init__(self):
        self.db = get_db_padel_times
    
    async def get_all_clubs(self):
        """Get all clubs from the database"""
        try:
            clubs_collection = self.db()['clubs']
            clubs = list(clubs_collection.find({}))
            
            # Convert ObjectId to string for JSON serialization
            for club in clubs:
                club['_id'] = str(club['_id'])
            
            return clubs
            
        except Exception as e:
            logger.error(f"Error in get_all_clubs: {str(e)}")
            raise e
    
    async def get_courts(self):
        """Get courts information - implement from getCourts Lambda"""
        try:
            # TODO: Implement logic from getCourts Lambda function
            # For now, return a placeholder response
            return {
                "message": "Courts endpoint - implement from getCourts Lambda",
                "status": "placeholder"
            }
        except Exception as e:
            logger.error(f"Error in get_courts: {str(e)}")
            raise e 