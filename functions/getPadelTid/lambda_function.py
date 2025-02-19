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
        
        # Add weather and location conditions
        if locations:
            location_conditions = []
            for location in locations:
                location_conditions.append({
                    '$and': [
                        {f'clubs.{location}': {'$exists': True}},
                        {f'clubs.{location}.weather.wind_speed': {'$lt': wind_speed_threshold}},
                        {f'clubs.{location}.weather.precipitation_probability': {'$lt': precipitation_probability_threshold}}
                    ]
                })
            query['$or'] = location_conditions
        else:
            # If no locations specified, check all clubs
            query['$expr']['$and'].append({
                '$or': [
                    {
                        '$and': [
                            {f'clubs.{club}.weather.wind_speed': {'$lt': wind_speed_threshold}},
                            {f'clubs.{club}.weather.precipitation_probability': {'$lt': precipitation_probability_threshold}}
                        ]
                    }
                    for club in db['clubs'].distinct('name')
                ]
            })
            
        if showUnavailableSlots == "false":
            query['$or'] = query.get('$or', []).extend([
                {f'clubs.{loc}.available_slots': {'$gt': 0}} 
                for loc in (locations if locations else db['clubs'].distinct('name'))
            ])

        print("Query:", query)
        results = list(collection.find(query, {'_id': 0}))
        print("Results:", results)

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
