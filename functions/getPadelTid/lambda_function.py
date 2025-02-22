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
    user = db_padeltid['users'].find_one({"_id": user_id})
    if not user or 'subscriptions' not in user:
        return set()
    
    # Extract just the IDs from the subscription objects
    return {sub['id'] for sub in user.get('subscriptions', [])}

def lambda_handler(event,context):
    try:
        wind_speed_threshold = float(event['queryStringParameters']['wind_speed_threshold'])
        precipitation_probability_threshold = float(event['queryStringParameters']['precipitation_probability_threshold'])
        temperature_threshold = float(event['queryStringParameters']['temperature_threshold'])
        showUnavailableSlots = event['queryStringParameters']['showUnavailableSlots']
        locations = event['queryStringParameters'].get('locations', '').split(',')
        locations = [loc for loc in locations if loc]
        
        # Get user_id if provided
        user_id = event['queryStringParameters'].get('user_id')
        user_subscriptions = get_user_subscriptions(user_id)
        
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
