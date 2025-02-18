import json
import os
from pymongo import MongoClient

def lambda_handler(event, context):
    try:
        # Connect to MongoDB
        client = MongoClient(host=os.environ.get("ATLAS_URI"))
        db = client['padelTimes']
        clubs_collection = db['clubs']
        
        
        # Get all clubs
        clubs = list(clubs_collection.find({}, {'_id': str}))
        
        # Convert ObjectId to string for JSON serialization
        for club in clubs:
            club['_id'] = str(club['_id'])
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps(clubs)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        } 