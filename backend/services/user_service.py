from config.database import get_db_padeltid
from typing import Literal, Optional
import logging

logger = logging.getLogger(__name__)

class UserService:
    def __init__(self):
        self.db = get_db_padeltid
    
    async def get_user_properties(self, user_id: str) -> dict:
        """Get user properties (skillLevel and courtSide)"""
        try:
            users_collection = self.db()['users']
            user = users_collection.find_one({"_id": user_id})
            
            if not user:
                # Return default properties if user not found
                return {
                    "skillLevel": 3.5,
                    "courtSide": "both"
                }
            
            return {
                "skillLevel": user.get("skillLevel", 3.5),
                "courtSide": user.get("courtSide", "both")
            }
        except Exception as e:
            logger.error(f"Error getting user properties for {user_id}: {str(e)}")
            raise e
    
    async def update_user_properties(
        self, 
        user_id: str, 
        skill_level: float, 
        court_side: Literal['left', 'right', 'both']
    ) -> dict:
        """Update user properties (skillLevel and courtSide)"""
        try:
            # Validate skill level
            if not (1.0 <= skill_level <= 7.0):
                raise ValueError("Skill level must be between 1.0 and 7.0")
            
            # Validate court side
            if court_side not in ['left', 'right', 'both']:
                raise ValueError("Court side must be 'left', 'right', or 'both'")
            
            users_collection = self.db()['users']
            
            # Update user document
            result = users_collection.update_one(
                {"_id": user_id},
                {
                    "$set": {
                        "skillLevel": skill_level,
                        "courtSide": court_side
                    }
                },
                upsert=True  # Create user if not found
            )
            
            if result.matched_count == 0 and result.upserted_id:
                logger.info(f"Created new user with properties: {user_id}")
            elif result.modified_count > 0:
                logger.info(f"Updated user properties for: {user_id}")
            
            return {
                "message": "User properties updated successfully",
                "skillLevel": skill_level,
                "courtSide": court_side
            }
        except ValueError as e:
            logger.error(f"Validation error for user {user_id}: {str(e)}")
            raise e
        except Exception as e:
            logger.error(f"Error updating user properties for {user_id}: {str(e)}")
            raise e