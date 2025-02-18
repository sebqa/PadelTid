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
        locations = [loc for loc in locations if loc] # Remove empty strings
        
        current_time = datetime.now()
        current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')
        
        # Base query
        query = {
            'precipitation_probability': {'$lt': precipitation_probability_threshold},
            'wind_speed': {'$lt': wind_speed_threshold},
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
        
        # Add location filter if locations are specified
        if locations:
            query['$or'] = [
                {f'clubs.{location}': {'$exists': True}} 
                for location in locations
            ]
            
        if showUnavailableSlots == "false":
            query['available_slots'] = {'$gt': 0}

        print("Query:", query)  # Debug print
        results = list(collection.find(query, {'_id': 0}))
        print("Results:", results)  # Debug print

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps(results)
        }
    except Exception as e:
        print("Error:", str(e))  # Debug print
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }
