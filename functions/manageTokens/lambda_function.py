import json
import os
from pymongo import MongoClient
from datetime import datetime, timedelta

def lambda_handler(event, context):
    try:
        print("Received event:", event)  # Debug log
        client = MongoClient(os.environ.get("ATLAS_URI"))
        db = client['padeltid']
        collection = db['users']

        # Check if this is an API Gateway request
        if 'httpMethod' in event:
            # Handle API Gateway request
            if event['httpMethod'] == 'GET':
                user_id = event.get('queryStringParameters', {}).get('userId')
                if not user_id:
                    raise ValueError("Missing userId in GET request")
                return get_user_tokens(collection, user_id)
            elif event['httpMethod'] == 'POST':
                body = json.loads(event.get('body', '{}'))
                print("Request body:", body)
            else:
                raise ValueError(f"Unsupported HTTP method: {event.get('httpMethod')}")
        else:
            # Handle direct Lambda invocation
            body = event

        # Process the request body (either from API Gateway or direct invocation)
        user_id = body.get('userId')
        token = body.get('token')
        action = body.get('action')
        
        if not all([user_id, token, action]):
            raise ValueError(f"Missing required fields. Got: {body}")
        
        if action == 'save':
            return save_token(collection, user_id, token, body.get('platform'))
        elif action == 'remove':
            return remove_token(collection, user_id, token)
        else:
            raise ValueError(f"Invalid action: {action}")

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")  # Debug log
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
    try:
        user = collection.find_one({'_id': user_id})
        tokens = []
        
        if user and 'tokens' in user:
            current_time = datetime.utcnow()
            tokens = [
                token['token'] for token in user['tokens']
                if token.get('lastUsedAt') and
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
    except Exception as e:
        print(f"Error in get_user_tokens: {str(e)}")
        raise

def save_token(collection, user_id, token, platform):
    try:
        current_time = datetime.utcnow().isoformat()
        
        # Update or insert token
        result = collection.update_one(
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
        
        print(f"MongoDB update result: {result.modified_count} documents modified")  # Debug log

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'success': True})
        }
    except Exception as e:
        print(f"Error in save_token: {str(e)}")
        raise

def remove_token(collection, user_id, token):
    try:
        result = collection.update_one(
            {'_id': user_id},
            {'$pull': {'tokens': {'token': token}}}
        )
        
        print(f"MongoDB remove result: {result.modified_count} documents modified")  # Debug log

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'success': True})
        }
    except Exception as e:
        print(f"Error in remove_token: {str(e)}")
        raise 