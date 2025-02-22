import json
import os
from pymongo import MongoClient
from datetime import datetime, timedelta

def lambda_handler(event, context):
    try:
        client = MongoClient(os.environ.get("ATLAS_URI"))
        db = client['padeltid']
        collection = db['users']

        # Handle GET request (get tokens)
        if event['httpMethod'] == 'GET':
            user_id = event['queryStringParameters']['userId']
            return get_user_tokens(collection, user_id)

        # Handle POST request (save/remove token)
        if event['httpMethod'] == 'POST':
            body = json.loads(event['body'])
            user_id = body['userId']
            token = body['token']
            action = body['action']
            
            if action == 'save':
                return save_token(collection, user_id, token, body.get('platform'))
            elif action == 'remove':
                return remove_token(collection, user_id, token)

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

def get_user_tokens(collection, user_id):
    user = collection.find_one({'_id': user_id})
    tokens = []
    
    if user and 'tokens' in user:
        # Filter out tokens older than 30 days
        current_time = datetime.utcnow()
        tokens = [
            token['token'] for token in user['tokens']
            if 'lastUsedAt' in token and
            datetime.fromisoformat(token['lastUsedAt']) > current_time - timedelta(days=30)
        ]

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({'tokens': tokens})
    }

def save_token(collection, user_id, token, platform):
    current_time = datetime.utcnow().isoformat()
    
    # Update or insert token
    collection.update_one(
        {'_id': user_id},
        {
            '$pull': {'tokens': {'token': token}},  # Remove old token entry if exists
            '$push': {
                'tokens': {
                    'token': token,
                    'platform': platform,
                    'createdAt': current_time,
                    'lastUsedAt': current_time
                }
            }
        },
        upsert=True
    )

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({'success': True})
    }

def remove_token(collection, user_id, token):
    collection.update_one(
        {'_id': user_id},
        {'$pull': {'tokens': {'token': token}}}
    )

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({'success': True})
    } 