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
    
    def save_user_preferences(self, user_id, preferences):
        """Save user filter preferences to the database with denormalized structure"""
        try:
            if not user_id:
                return
            
            # Extract base preferences
            base_preferences = {
                "notifyOnMatchingCourts": preferences.get("notifyOnMatchingCourts", False),
                "showUnavailableSlots": preferences.get("notification_show_unavailable_courts", False),
                "locations": preferences.get("locations", [])
            }
            
            # Create location-specific preference structure
            location_preferences = {}
            for location in preferences.get("locations", []):
                location_preferences[location] = {
                    "wind_threshold": preferences.get("notification_wind_threshold"),
                    "min_temp": preferences.get("notification_temperature_threshold"),
                    "precip_threshold": preferences.get("notification_precipitation_threshold")
                }

            # Complete preferences structure
            optimized_preferences = {
                **base_preferences,
                "locationPreferences": location_preferences
            }

            # Update the user document
            result = self.db_padeltid()['users'].update_one(
                {"_id": user_id}, 
                {"$set": {"filterPreferences": optimized_preferences}},
                upsert=False  # Don't create a new user if not found
            )
            
            if result.modified_count > 0:
                logger.info(f"Updated filter preferences for user: {user_id}")
            else:
                logger.info(f"No changes made to filter preferences for user: {user_id}")
                
        except Exception as e:
            logger.error(f"Error saving user preferences: {str(e)}")
    
    async def get_recommendations(self, user_id: str, locations: list, court_type: str = "both"):
        """Get recommended padel times for a specific user based on their preferences"""
        try:
            # Validate user exists
            user = self.db_padeltid()['users'].find_one({"_id": user_id})
            if not user:
                raise ValueError("User not found")
                
            if not locations:
                raise ValueError("At least one location must be specified")
            
            # Get user follow data to mark documents as followed
            user_follows = self.get_user_follows(user_id)
                
            # Default weather thresholds if not in user preferences
            default_wind = 4.0  # Default wind threshold (m/s)
            default_precip = 10.0  # Default precipitation probability (%)
            default_temp = 5.0  # Default minimum temperature (°C)
            
            current_time = datetime.now()
            current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')
            
            # Base query - similar to filtered documents but with user-specific thresholds
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
                    {f'clubs.{club}.available_slots': {'$gt': 0}}  # Only available slots for recommendations
                ]
                
                # For now, use simple approach with weather filtering for outdoor/both
                if court_type == "indoor":
                    # Indoor courts: skip weather filtering
                    base_conditions.append({f'clubs.{club}.courts_breakdown.indoor.available': {'$gt': 0}})
                elif court_type == "outdoor":
                    # Outdoor courts: apply weather conditions 
                    base_conditions.extend([
                        {f'clubs.{club}.weather.wind_speed': {'$lte': default_wind}},
                        {f'clubs.{club}.weather.precipitation_probability': {'$lte': default_precip}},
                        {f'clubs.{club}.weather.air_temperature': {'$gte': default_temp}},
                    ])
                else:  # court_type == "both" - just apply weather to all
                    base_conditions.extend([
                        {f'clubs.{club}.weather.wind_speed': {'$lte': default_wind}},
                        {f'clubs.{club}.weather.precipitation_probability': {'$lte': default_precip}},
                        {f'clubs.{club}.weather.air_temperature': {'$gte': default_temp}},
                    ])
                    
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

            # Get results with limit to avoid too many recommendations
            collection = self.db_padel_times()['times']
            results = list(collection.find(query, projection).sort([("date", 1), ("time", 1)]).limit(20))
            
            # Clean up results and format them
            cleaned_results = []
            for doc in results:
                filtered_clubs = {}
                
                for name, data in doc.get('clubs', {}).items():
                    # Skip if club data is missing or not in requested clubs
                    if data is None or name not in locations:
                        continue
                    
                    # Skip if club doesn't have both weather and availability data
                    if 'weather' not in data or 'available_slots' not in data:
                        continue
                        
                    available_slots = data.get('available_slots', 0)
                    if available_slots > 0:
                        filtered_clubs[name] = data
                
                if filtered_clubs:  # Only include document if it has valid clubs
                    # Format date and time for follow check
                    date_to_follow_id = (
                        doc['date'].replace('-', '') +  # YYYYMMDD
                        doc['time'].split(':')[0].zfill(2) +  # HH (padded with zeros)
                        doc['time'].split(':')[1].zfill(2) +  # MM (padded with zeros)
                        "00"  # Add seconds
                    )
                    
                    logger.info(f"Document date: {doc['date']}, time: {doc['time']}")
                    logger.info(f"Generated follow ID: {date_to_follow_id}")
                    
                    is_followed = False
                    preferences = None
                    
                    if user_id:
                        logger.info(f"Checking follows for user_id: {user_id}")
                        # Find this document in user's follows
                        for follow in user_follows:
                            logger.info(f"Checking follow: {follow}")
                            if isinstance(follow, dict):
                                follow_id = follow.get('id', '')
                                logger.info(f"Comparing follow ID {follow_id} with {date_to_follow_id}")
                                if follow_id == date_to_follow_id:
                                    logger.info(f"Found matching follow!")
                                    is_followed = True
                                    if 'preferences' in follow:
                                        preferences = follow['preferences']
                                        logger.info(f"Found preferences: {preferences}")
                                    break
                    
                    cleaned_doc = {
                        'date': doc['date'],
                        'time': doc['time'],
                        'clubs': filtered_clubs,
                        'followed': is_followed
                    }
                    
                    # Include preferences in the response if available
                    if preferences:
                        logger.info(f"Adding preferences to response for {date_to_follow_id}: {preferences}")
                        cleaned_doc['preferences'] = preferences
                    else:
                        logger.info(f"No preferences found for {date_to_follow_id}")
                    
                    cleaned_results.append(cleaned_doc)

            return cleaned_results
            
        except Exception as e:
            logger.error(f"Error in get_recommendations: {str(e)}")
            raise e
    
    async def get_filtered_documents(self, wind_speed_threshold: float, precipitation_probability_threshold: float, 
                                    temperature_threshold: float, show_unavailable_slots: bool, 
                                    locations: list, user_id: str = None, court_type: str = "both"):
        """Get filtered padel documents based on weather and location criteria"""
        try:
            user_follows = self.get_user_follows(user_id) if user_id else []
            
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
            
            # Determine which clubs to include
            clubs_to_check = locations if locations else []
            if not clubs_to_check:
                # If no specific locations provided, get all available clubs
                clubs_collection = self.db_padel_times()['clubs']
                clubs_to_check = clubs_collection.distinct('name')
            
            # Add weather and location conditions
            club_conditions = []
            for club in clubs_to_check:
                base_conditions = [
                    {f'clubs.{club}': {'$exists': True}},
                ]
                
                # For now, use simple approach with weather filtering for outdoor/both
                # This ensures backward compatibility while we populate the new court breakdown data
                if court_type == "indoor":
                    # Indoor courts: skip weather filtering (not many indoor courts in current data)
                    base_conditions.append({f'clubs.{club}.courts_breakdown.indoor.available': {'$gt': 0}})
                elif court_type == "outdoor":
                    # Outdoor courts: apply weather conditions 
                    base_conditions.extend([
                        {f'clubs.{club}.weather.wind_speed': {'$lte': wind_speed_threshold}},
                        {f'clubs.{club}.weather.precipitation_probability': {'$lte': precipitation_probability_threshold}},
                        {f'clubs.{club}.weather.air_temperature': {'$gte': temperature_threshold}},
                    ])
                else:  # court_type == "both" - just apply weather to all (most current data is outdoor)
                    base_conditions.extend([
                        {f'clubs.{club}.weather.wind_speed': {'$lte': wind_speed_threshold}},
                        {f'clubs.{club}.weather.precipitation_probability': {'$lte': precipitation_probability_threshold}},
                        {f'clubs.{club}.weather.air_temperature': {'$gte': temperature_threshold}},
                    ])
                
                if not show_unavailable_slots:
                    base_conditions.append({f'clubs.{club}.available_slots': {'$gt': 0}})
                    
                club_conditions.append({'$and': base_conditions})
                
            query['$or'] = club_conditions

            # Create projection to only return necessary fields
            projection = {
                '_id': 0,
                'date': 1,
                'time': 1,
            }
            # Add only the requested clubs to the projection
            for club in clubs_to_check:
                projection[f'clubs.{club}'] = 1

            # Add sort to the query - sort by date and time
            collection = self.db_padel_times()['times']
            results = list(collection.find(query, projection).sort([("date", 1), ("time", 1)]))
            
            # Clean up results to remove empty clubs and handle available slots
            cleaned_results = []
            for doc in results:
                filtered_clubs = {}
                
                for name, data in doc.get('clubs', {}).items():
                    # Skip if club data is missing or not in requested clubs
                    if data is None or name not in clubs_to_check:
                        continue
                    
                    # Skip if club doesn't have both weather and availability data
                    if 'weather' not in data or 'available_slots' not in data:
                        continue
                        
                    available_slots = data.get('available_slots', 0)
                    if show_unavailable_slots or available_slots > 0:
                        filtered_clubs[name] = data
                
                if filtered_clubs:  # Only include document if it has valid clubs
                    # Format date and time for follow check
                    date_to_follow_id = (
                        doc['date'].replace('-', '') +  # YYYYMMDD
                        doc['time'].split(':')[0].zfill(2) +  # HH (padded with zeros)
                        doc['time'].split(':')[1].zfill(2) +  # MM (padded with zeros)
                        "00"  # Add seconds
                    )
                    
                    logger.info(f"Document date: {doc['date']}, time: {doc['time']}")
                    logger.info(f"Generated follow ID: {date_to_follow_id}")
                    
                    is_followed = False
                    preferences = None
                    
                    if user_id:
                        logger.info(f"Checking follows for user_id: {user_id}")
                        # Find this document in user's follows
                        for follow in user_follows:
                            logger.info(f"Checking follow: {follow}")
                            if isinstance(follow, dict):
                                follow_id = follow.get('id', '')
                                logger.info(f"Comparing follow ID {follow_id} with {date_to_follow_id}")
                                if follow_id == date_to_follow_id:
                                    logger.info(f"Found matching follow!")
                                    is_followed = True
                                    if 'preferences' in follow:
                                        preferences = follow['preferences']
                                        logger.info(f"Found preferences: {preferences}")
                                    break
                    
                    cleaned_doc = {
                        'date': doc['date'],
                        'time': doc['time'],
                        'clubs': filtered_clubs,
                        'followed': is_followed
                    }
                    
                    # Include preferences in the response if available
                    if preferences:
                        logger.info(f"Adding preferences to response for {date_to_follow_id}: {preferences}")
                        cleaned_doc['preferences'] = preferences
                    else:
                        logger.info(f"No preferences found for {date_to_follow_id}")
                    
                    cleaned_results.append(cleaned_doc)

            return cleaned_results
            
        except Exception as e:
            logger.error(f"Error in get_filtered_documents: {str(e)}")
            raise e
    
    async def get_document_by_id(self, doc_id: str):
        """Get document by ID - migrated from getDocumentById Lambda"""
        try:
            if not doc_id:
                raise ValueError("Missing documentId parameter")
            
            # Validate document ID format (should be YYYYMMDDHHMMSS - 14 characters)
            if len(doc_id) != 14 or not doc_id.isdigit():
                raise ValueError("Invalid documentId format. Expected YYYYMMDDHHMMSS")
            
            # Parse date and time from document ID (format: YYYYMMDDHHMMSS)
            date_str = f"{doc_id[0:4]}-{doc_id[4:6]}-{doc_id[6:8]}"  # YYYY-MM-DD
            time_str = f"{doc_id[8:10]}:{doc_id[10:12]}:00"  # HH:MM:SS
            
            logger.info(f"Searching for document with date: {date_str}, time: {time_str}")
            
            # Query the database for the specific document
            collection = self.db_padel_times()['times']
            document = collection.find_one({
                'date': date_str,
                'time': time_str
            })
            
            if not document:
                logger.info(f"Document not found for ID: {doc_id}")
                raise ValueError("Document not found")
            
            # Convert MongoDB ObjectId to string for JSON serialization
            if '_id' in document:
                document['_id'] = str(document['_id'])
            
            logger.info(f"Successfully retrieved document for ID: {doc_id}")
            return document
            
        except ValueError as e:
            logger.error(f"Validation error in get_document_by_id: {str(e)}")
            raise e
        except Exception as e:
            logger.error(f"Error in get_document_by_id: {str(e)}")
            raise e 