from pymongo import MongoClient
from datetime import datetime
import json,os

# Set up MongoDB connection
client = MongoClient(host=os.environ.get("ATLAS_URI"))
db = client['padelTimes']
collection = db['times']


def lambda_handler(event,context):
    try:
        wind_speed_threshold = float(event['queryStringParameters']['wind_speed_threshold'])
        precipitation_probability_threshold = float(event['queryStringParameters']['precipitation_probability_threshold'])
        showUnavailableSlots = event['queryStringParameters']['showUnavailableSlots']
        locations = event['queryStringParameters'].get('locations', '').split(',')
        locations = [loc for loc in locations if loc]
        
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
        clubs_to_check = locations if locations else db['clubs'].distinct('name')
        
        # Add weather and location conditions
        club_conditions = []
        for club in clubs_to_check:
            base_conditions = [
                {f'clubs.{club}': {'$exists': True}},
                {f'clubs.{club}.weather.wind_speed': {'$lt': wind_speed_threshold}},
                {f'clubs.{club}.weather.precipitation_probability': {'$lt': precipitation_probability_threshold}}
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
        results = list(collection.find(query, projection))
        
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
                cleaned_doc = {
                    'date': doc['date'],
                    'time': doc['time'],
                    'clubs': filtered_clubs
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
