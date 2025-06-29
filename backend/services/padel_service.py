from config.database import get_db_padel_times, get_db_padeltid
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class PadelService:
    def __init__(self):
        self.db_padel_times = get_db_padel_times
        self.db_padeltid = get_db_padeltid
    
    def get_user_follows(self, user_id):
        """Get user follows from database"""
        if not user_id:
            logger.info("No user_id provided")
            return []
        try:
            logger.info(f"Fetching follows for user: {user_id}")
            user = self.db_padeltid()['users'].find_one({"_id": user_id})
            if not user:
                logger.info(f"No user found for ID: {user_id}")
                return []
                
            follows = user.get('follows', [])
            if not follows:
                logger.info(f"No follows found for user: {user_id}")
                return []
                
            logger.info(f"Raw follows from DB: {follows}")
            
            # Handle the specific follow format
            follow_data = []
            for follow in follows:
                if isinstance(follow, dict) and 'id' in follow:
                    logger.info(f"Processing follow: {follow}")
                    follow_data.append(follow)
                    
            logger.info(f"Processed follow data: {follow_data}")
            return follow_data
            
        except Exception as e:
            logger.error(f"Error in get_user_follows: {str(e)}")
            return []
    
    async def get_recommendations(self, user_id: str, locations: list):
        """Get recommended padel times for a specific user"""
        try:
            # Validate user exists
            user = self.db_padeltid()['users'].find_one({"_id": user_id})
            if not user:
                raise ValueError("User not found")
                
            if not locations:
                raise ValueError("At least one location must be specified")
            
            # Get user follow data to mark documents as followed
            user_follows = self.get_user_follows(user_id)
                
            # Default weather thresholds
            default_wind = 4.0
            default_precip = 10.0
            default_temp = 5.0
            
            current_time = datetime.now()
            current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')
            
            # Base query
            query = {
                '$expr': {
                    '$and': [
                        {'$gt': [{'$concat': ['$date', ' ', '$time']}, current_time_str]},
                        {'$or': [
                            {'$regexMatch': {'input': '$time', 'regex': '^0[6-9]:'}},
                            {'$regexMatch': {'input': '$time', 'regex': '^1[0-9]:'}},
                            {'$regexMatch': {'input': '$time', 'regex': '^2[0-4]:'}}
                        ]}
                    ]
                }
            }
            
            # Add location and weather conditions
            club_conditions = []
            for club in locations:
                base_conditions = [
                    {f'clubs.{club}': {'$exists': True}},
                    {f'clubs.{club}.weather.wind_speed': {'$lte': default_wind}},
                    {f'clubs.{club}.weather.precipitation_probability': {'$lte': default_precip}},
                    {f'clubs.{club}.weather.air_temperature': {'$gte': default_temp}},
                    {f'clubs.{club}.available_slots': {'$gt': 0}}
                ]
                    
                club_conditions.append({'$and': base_conditions})
                
            query['$or'] = club_conditions

            # Create projection
            projection = {
                '_id': 0,
                'date': 1,
                'time': 1,
            }
            # Add only the requested clubs to the projection
            for club in locations:
                projection[f'clubs.{club}'] = 1

            # Get results with limit
            collection = self.db_padel_times()['times']
            results = list(collection.find(query, projection).sort([("date", 1), ("time", 1)]).limit(20))
            
            # Clean up results and format them
            cleaned_results = []
            for doc in results:
                filtered_clubs = {}
                
                for name, data in doc.get('clubs', {}).items():
                    if data is None or name not in locations:
                        continue
                    
                    if 'weather' not in data or 'available_slots' not in data:
                        continue
                        
                    available_slots = data.get('available_slots', 0)
                    if available_slots > 0:
                        filtered_clubs[name] = data
                
                if filtered_clubs:
                    # Format date and time for follow check
                    date_to_follow_id = (
                        doc['date'].replace('-', '') +
                        doc['time'].split(':')[0].zfill(2) +
                        doc['time'].split(':')[1].zfill(2) +
                        "00"
                    )
                    
                    is_followed = False
                    preferences = None
                    
                    if user_id:
                        for follow in user_follows:
                            if isinstance(follow, dict):
                                follow_id = follow.get('id', '')
                                if follow_id == date_to_follow_id:
                                    is_followed = True
                                    if 'preferences' in follow:
                                        preferences = follow['preferences']
                                    break
                    
                    cleaned_doc = {
                        'date': doc['date'],
                        'time': doc['time'],
                        'clubs': filtered_clubs,
                        'followed': is_followed
                    }
                    
                    if preferences:
                        cleaned_doc['preferences'] = preferences
                    
                    cleaned_results.append(cleaned_doc)

            return cleaned_results
            
        except Exception as e:
            logger.error(f"Error in get_recommendations: {str(e)}")
            raise e
    
    async def get_document_by_id(self, doc_id: str):
        """Get document by ID"""
        try:
            # TODO: Implement logic from getDocumentById Lambda
            return {
                "message": f"Document {doc_id} endpoint - implement from getDocumentById Lambda",
                "documentId": doc_id
            }
        except Exception as e:
            logger.error(f"Error in get_document_by_id: {str(e)}")
            raise e 