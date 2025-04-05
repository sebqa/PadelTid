from pymongo import MongoClient
from datetime import datetime
import json,os

# Set up MongoDB connection
client = MongoClient(host=os.environ.get("ATLAS_URI"))
db_padel_times = client['padelTimes']
db_padeltid = client['padeltid']
collection = db_padel_times['times']

def get_user_subscriptions(user_id):
    if not user_id:
        return set()
    try:
        user = db_padeltid['users'].find_one({"_id": user_id})
        if not user:
            print(f"No user found for ID: {user_id}")
            return set()
            
        subscriptions = user.get('subscriptions', [])
        if not subscriptions:
            print(f"No subscriptions found for user: {user_id}")
            return set()
            
        print(f"Raw subscriptions: {subscriptions}")
        
        # Handle both old and new subscription formats
        subscription_ids = set()
        for sub in subscriptions:
            if isinstance(sub, dict):
                # New format: {"id": "...", "preferences": {...}}
                if 'id' in sub:
                    subscription_ids.add(sub['id'])
            else:
                # Old format: direct string ID
                subscription_ids.add(sub)
                
        print(f"Extracted subscription IDs: {subscription_ids}")
        return subscription_ids
        
    except Exception as e:
        print(f"Error in get_user_subscriptions: {str(e)}")
        return set()

def get_recommended_times(user_id, locations):
    """
    Get recommended padel times for a specific user based on their preferences
    """
    try:
        # Validate user exists
        user = db_padeltid['users'].find_one({"_id": user_id})
        if not user:
            return {"error": "User not found"}, 404
            
        # Make sure locations is a list
        if isinstance(locations, str):
            locations = [loc for loc in locations.split(',') if loc]
        if not locations:
            return {"error": "At least one location must be specified"}, 400
            
        # TODO: Implement actual recommendation logic here
        # For now, return placeholder data structure
        current_time = datetime.now()
        current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')
        
        # Using empty placeholders for now - will be replaced with actual recommendation logic
        recommended_times = []
        
        return recommended_times, 200
        
    except Exception as e:
        print(f"Error in get_recommended_times: {str(e)}")
        return {"error": str(e)}, 500

def save_user_preferences(user_id, preferences):
    """
    Save user filter preferences to the database with denormalized structure
    """
    try:
        if not user_id:
            return
        
        # Extract base preferences
        base_preferences = {
            "notifyOnMatchingCourts": preferences.get("notifyOnMatchingCourts", False),
            "showUnavailableSlots": preferences.get("showUnavailableSlots", False),
            "locations": preferences.get("locations", [])
        }
        
        # Create location-specific preference structure
        location_preferences = {}
        for location in preferences.get("locations", []):
            location_preferences[location] = {
                "wind_threshold": preferences.get("wind_speed_threshold"),
                "min_temp": preferences.get("temperature_threshold"),
                "precip_threshold": preferences.get("precipitation_probability_threshold")
            }
        
        # Complete preferences structure
        optimized_preferences = {
            **base_preferences,
            "locationPreferences": location_preferences
        }
        
        # Update the user document
        result = db_padeltid['users'].update_one(
            {"_id": user_id}, 
            {"$set": {"filterPreferences": optimized_preferences}},
            upsert=False  # Don't create a new user if not found
        )
        
        if result.modified_count > 0:
            print(f"Updated filter preferences for user: {user_id}")
        else:
            print(f"No changes made to filter preferences for user: {user_id}")
            
    except Exception as e:
        print(f"Error saving user preferences: {str(e)}")

def lambda_handler(event,context):
    try:
        # Check if this is a request for recommendations
        is_recommendation_request = event['queryStringParameters'].get('recommendation', 'false').lower() == 'true'
        
        if is_recommendation_request:
            # Handle recommendation request
            user_id = event['queryStringParameters'].get('user_id')
            if not user_id:
                raise ValueError("user_id is required for recommendation requests")
                
            locations = event['queryStringParameters'].get('locations', '')
            if not locations:
                raise ValueError("locations is required for recommendation requests")
                
            locations = locations.split(',')
            locations = [loc for loc in locations if loc]
            
            recommended_times, status_code = get_recommended_times(user_id, locations)
            
            if status_code != 200:
                return {
                    'statusCode': status_code,
                    'headers': {
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps(recommended_times)
                }
            
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps(recommended_times)
            }
        
        # Standard request flow continues below
        wind_speed_threshold = float(event['queryStringParameters']['wind_speed_threshold'])
        precipitation_probability_threshold = float(event['queryStringParameters']['precipitation_probability_threshold'])
        temperature_threshold = float(event['queryStringParameters']['temperature_threshold'])
        showUnavailableSlots = event['queryStringParameters']['showUnavailableSlots']
        locations = event['queryStringParameters'].get('locations', '').split(',')
        locations = [loc for loc in locations if loc]
        
        # Get user_id if provided
        user_id = event['queryStringParameters'].get('user_id')
        user_subscriptions = get_user_subscriptions(user_id)
        
        # Save user preferences if user_id is provided
        if user_id:
            preferences = {
                "wind_speed_threshold": wind_speed_threshold,
                "precipitation_probability_threshold": precipitation_probability_threshold,
                "temperature_threshold": temperature_threshold,
                "showUnavailableSlots": showUnavailableSlots == "true",
                "locations": locations,
                "notifyOnMatchingCourts": event['queryStringParameters'].get('notify_on_matching_courts', 'false') == "true"
            }
            save_user_preferences(user_id, preferences)
        
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
        clubs_to_check = locations if locations else db_padel_times['clubs'].distinct('name')
        
        # Add weather and location conditions
        club_conditions = []
        for club in clubs_to_check:
            base_conditions = [
                {f'clubs.{club}': {'$exists': True}},
                {f'clubs.{club}.weather.wind_speed': {'$lte': wind_speed_threshold}},
                {f'clubs.{club}.weather.precipitation_probability': {'$lte': precipitation_probability_threshold}},
                {f'clubs.{club}.weather.air_temperature': {'$gte': temperature_threshold}},
            ]
            
            if showUnavailableSlots == "false":
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

        print("Query:", query)
        # Add sort to the query - sort by date and time
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
                if showUnavailableSlots == "true" or available_slots > 0:
                    filtered_clubs[name] = data
            
            if filtered_clubs:  # Only include document if it has valid clubs
                # Format date and time for subscription check
                subscription_id = doc['date'].replace('-', '') + doc['time'].replace(':', '') + '00'
                cleaned_doc = {
                    'date': doc['date'],
                    'time': doc['time'],
                    'clubs': filtered_clubs,
                    'subscribed': subscription_id in user_subscriptions if user_id else False
                }
                cleaned_results.append(cleaned_doc)

        print("Results:", cleaned_results)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps(cleaned_results)
        }
    except Exception as e:
        print("Error:", str(e))
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }
