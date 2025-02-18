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
        current_time = datetime.now()  # Get the current date and time
        current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')  # Format current time as string
        
        # Query the collection
        query = {
            'precipitation_probability': {'$lt': precipitation_probability_threshold},
            'wind_speed': {'$lt': wind_speed_threshold},
            '$expr': {
                '$and': [
                    { '$gt': [
                        { '$concat': ['$date', ' ', '$time'] },
                        current_time_str
                    ]},
                    { '$gte': [{ '$toInt': { '$substr': ['$time', 0, 2] }}, 6] },
                    { '$lte': [{ '$toInt': { '$substr': ['$time', 0, 2] }}, 24] }
                ] 
            }
        }
        if showUnavailableSlots == "false":
            query['available_slots'] = {'$gt': 0}

        results = list(collection.find(query, {'_id': 0}))

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
        return json.dumps({'error': str(e)})
