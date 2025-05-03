from pymongo import MongoClient
from datetime import datetime
import json,os

# Set up MongoDB connection
client = MongoClient(host=os.environ.get("ATLAS_URI"))
db_padel_times = client['padelTimes']
db_padeltid = client['padeltid']
collection = db_padel_times['times']

def get_user_follows(user_id):
    if not user_id:
        print("No user_id provided")
        return set()
    try:
        print(f"Fetching follows for user: {user_id}")
        user = db_padeltid['users'].find_one({"_id": user_id})
        if not user:
            print(f"No user found for ID: {user_id}")
            return set()
            
        follows = user.get('follows', [])
        if not follows:
            print(f"No follows found for user: {user_id}")
            return set()
            
        print(f"Raw follows from DB: {follows}")
        
        # Handle the specific follow format:
        # [{"id":"20250324120000","preferences":{...}}, {"id":"20250323060000","preferences":{...}}]
        follow_data = []
        for follow in follows:
            if isinstance(follow, dict) and 'id' in follow:
                print(f"Processing follow: {follow}")
                follow_data.append(follow)
                
        print(f"Processed follow data: {follow_data}")
        return follow_data
        
    except Exception as e:
        print(f"Error in get_user_follows: {str(e)}")
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
        
        # Get user filter preferences
        filter_prefs = user.get('filterPreferences', {})
        
        # Get user follow data to mark documents as followed
        user_follows = get_user_follows(user_id)
            
        # For now, just get documents that match the user's preferred locations and weather thresholds
        # In the future, you can implement more sophisticated recommendation logic
        
        # Default weather thresholds if not in user preferences
        default_wind = 10.0  # Default wind threshold (m/s)
        default_precip = 30.0  # Default precipitation probability (%)
        default_temp = 5.0  # Default minimum temperature (°C)
        
        # Get weather thresholds from user preferences, if available
        wind_threshold = default_wind
        precip_threshold = default_precip
        temp_threshold = default_temp
        
        # Get location-specific preferences if available
        location_prefs = filter_prefs.get('locationPreferences', {})
        
        # Get documents matching user preferences for each location
        recommended_docs = []
        
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
            # Get location-specific thresholds if available
            club_prefs = location_prefs.get(club, {})
            club_wind = club_prefs.get('wind_threshold', wind_threshold)
            club_precip = club_prefs.get('precip_threshold', precip_threshold)
            club_temp = club_prefs.get('min_temp', temp_threshold)
            
            # Convert string values to float if needed
            if isinstance(club_wind, str):
                club_wind = float(club_wind)
            if isinstance(club_precip, str):
                club_precip = float(club_precip)
            if isinstance(club_temp, str):
                club_temp = float(club_temp)
            
            base_conditions = [
                {f'clubs.{club}': {'$exists': True}},
                {f'clubs.{club}.weather.wind_speed': {'$lte': club_wind}},
                {f'clubs.{club}.weather.precipitation_probability': {'$lte': club_precip}},
                {f'clubs.{club}.weather.air_temperature': {'$gte': club_temp}},
                {f'clubs.{club}.available_slots': {'$gt': 0}}  # Only available slots for recommendations
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

        # Get results with limit to avoid too many recommendations
        results = list(collection.find(query, projection).sort([("date", 1), ("time", 1)]).limit(10))
        
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
                
                print(f"Document date: {doc['date']}, time: {doc['time']}")
                print(f"Generated follow ID: {date_to_follow_id}")
                print(f"Example expected format: 20250412060000")
                print(f"Available user_follows: {user_follows}")
                
                is_followed = False
                preferences = None
                
                if user_id:
                    print(f"Checking follows for user_id: {user_id}")
                    # Find this document in user's follows
                    for follow in user_follows:
                        print(f"Checking follow: {follow}")
                        if isinstance(follow, dict):
                            follow_id = follow.get('id', '')
                            print(f"Comparing follow ID {follow_id} with {date_to_follow_id}")
                            if follow_id == date_to_follow_id:
                                print(f"Found matching follow!")
                                is_followed = True
                                if 'preferences' in follow:
                                    preferences = follow['preferences']
                                    print(f"Found preferences: {preferences}")
                                break
                
                cleaned_doc = {
                    'date': doc['date'],
                    'time': doc['time'],
                    'clubs': filtered_clubs,
                    'followed': is_followed
                }
                
                # Include preferences in the response if available
                if preferences:
                    print(f"Adding preferences to response for {date_to_follow_id}: {preferences}")
                    cleaned_doc['preferences'] = preferences
                else:
                    print(f"No preferences found for {date_to_follow_id}")
                
                cleaned_results.append(cleaned_doc)

        return cleaned_results, 200
        
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
        
        # Create notification-specific preference structure if notifyOnMatchingCourts is enabled
        notification_preferences = None
        if preferences.get("notifyOnMatchingCourts", False):
            notification_preferences = {
                "wind_threshold": preferences.get("notification_wind_threshold", preferences.get("wind_speed_threshold")),
                "min_temp": preferences.get("notification_temperature_threshold", preferences.get("temperature_threshold")),
                "precip_threshold": preferences.get("notification_precipitation_threshold", preferences.get("precipitation_probability_threshold"))
            }
        
        # Complete preferences structure
        optimized_preferences = {
            **base_preferences,
            "locationPreferences": location_preferences
        }
        
        # Add notification preferences if present
        if notification_preferences:
            optimized_preferences["notificationPreferences"] = notification_preferences
        
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
        # Get parameters
        wind_speed_threshold = float(event['queryStringParameters']['wind_speed_threshold'])
        precipitation_probability_threshold = float(event['queryStringParameters']['precipitation_probability_threshold'])
        temperature_threshold = float(event['queryStringParameters']['temperature_threshold'])
        showUnavailableSlots = event['queryStringParameters']['showUnavailableSlots']
        locations = event['queryStringParameters'].get('locations', '').split(',')
        locations = [loc for loc in locations if loc]
        
        # Get user_id if provided
        user_id = event['queryStringParameters'].get('user_id')
        user_follows = get_user_follows(user_id)
        
        # Check if this is a combined request (fetch both filtered and recommended)
        fetch_both = event['queryStringParameters'].get('fetch_both', 'false').lower() == 'true'
        
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
            
            # Add notification-specific thresholds if provided
            if event['queryStringParameters'].get('notify_on_matching_courts', 'false') == "true":
                # Get notification-specific thresholds if provided, or use regular thresholds as defaults
                notification_wind = event['queryStringParameters'].get('notification_wind_threshold')
                notification_precip = event['queryStringParameters'].get('notification_precipitation_threshold')
                notification_temp = event['queryStringParameters'].get('notification_temperature_threshold')
                
                if notification_wind:
                    preferences["notification_wind_threshold"] = float(notification_wind)
                if notification_precip:
                    preferences["notification_precipitation_threshold"] = float(notification_precip)
                if notification_temp:
                    preferences["notification_temperature_threshold"] = float(notification_temp)
            
            save_user_preferences(user_id, preferences)
        
        # If this is a combined request, we need to fetch both types of data
        if fetch_both:
            # Get regular filtered documents
            filtered_results = get_filtered_documents(
                wind_speed_threshold, 
                precipitation_probability_threshold,
                temperature_threshold,
                showUnavailableSlots,
                locations,
                user_id,
                user_follows
            )
            
            # Get recommended documents
            recommended_results = []
            if user_id:
                recommended_results, _ = get_recommended_times(user_id, locations)
            
            # Return both in the response
            response_data = {
                "filtered": filtered_results,
                "recommended": recommended_results
            }
            
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps(response_data)
            }
        
        # Check if this is a request for recommendations only
        is_recommendation_request = event['queryStringParameters'].get('recommendation', 'false').lower() == 'true'
        
        if is_recommendation_request:
            # Handle recommendation request
            if not user_id:
                raise ValueError("user_id is required for recommendation requests")
                
            if not locations:
                raise ValueError("locations is required for recommendation requests")
                
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
        
        # Default case: just get filtered documents
        filtered_results = get_filtered_documents(
            wind_speed_threshold, 
            precipitation_probability_threshold,
            temperature_threshold,
            showUnavailableSlots,
            locations,
            user_id,
            user_follows
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps(filtered_results)
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

# Extract the document filtering logic to a separate function
def get_filtered_documents(
    wind_speed_threshold, 
    precipitation_probability_threshold,
    temperature_threshold,
    showUnavailableSlots,
    locations,
    user_id,
    user_follows
):
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
            # Format date and time for follow check
            date_to_follow_id = (
                doc['date'].replace('-', '') +  # YYYYMMDD
                doc['time'].split(':')[0].zfill(2) +  # HH (padded with zeros)
                doc['time'].split(':')[1].zfill(2) +  # MM (padded with zeros)
                "00"  # Add seconds
            )
            
            print(f"Document date: {doc['date']}, time: {doc['time']}")
            print(f"Generated follow ID: {date_to_follow_id}")
            print(f"Example expected format: 20250412060000")
            print(f"Available user_follows: {user_follows}")
            
            is_followed = False
            preferences = None
            
            if user_id:
                print(f"Checking follows for user_id: {user_id}")
                # Find this document in user's follows
                for follow in user_follows:
                    print(f"Checking follow: {follow}")
                    if isinstance(follow, dict):
                        follow_id = follow.get('id', '')
                        print(f"Comparing follow ID {follow_id} with {date_to_follow_id}")
                        if follow_id == date_to_follow_id:
                            print(f"Found matching follow!")
                            is_followed = True
                            if 'preferences' in follow:
                                preferences = follow['preferences']
                                print(f"Found preferences: {preferences}")
                            break
            
            cleaned_doc = {
                'date': doc['date'],
                'time': doc['time'],
                'clubs': filtered_clubs,
                'followed': is_followed
            }
            
            # Include preferences in the response if available
            if preferences:
                print(f"Adding preferences to response for {date_to_follow_id}: {preferences}")
                cleaned_doc['preferences'] = preferences
            else:
                print(f"No preferences found for {date_to_follow_id}")
            
            cleaned_results.append(cleaned_doc)

    return cleaned_results
