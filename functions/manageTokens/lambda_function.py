import json
import os
from pymongo import MongoClient
from datetime import datetime, timedelta

def lambda_handler(event, context):
    try:
        print("Received event:", event)  # Debug log
        print("HTTP Method:", event.get('requestContext', {}).get('http', {}).get('method'))
        
        headers = {
            'Access-Control-Allow-Headers': '*',  # More permissive during development
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            'Content-Type': 'application/json'
        }
        
        # Handle CORS preflight request
        if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
            print("Handling OPTIONS request")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'OK'})
            }

        client = MongoClient(os.environ.get("ATLAS_URI"))
        if not client:
            return error_response("Failed to connect to database", headers=headers)
            
        db = client['padeltid']
        collection = db['users']

        # Check if this is an API Gateway v2 request
        if 'requestContext' in event and 'http' in event['requestContext']:
            http_method = event['requestContext']['http']['method']
            print(f"Processing {http_method} request")
            
            if http_method == 'GET':
                user_id = event.get('queryStringParameters', {}).get('userId')
                if not user_id:
                    return error_response("Missing userId in GET request", headers=headers)
                return get_user_tokens(collection, user_id, headers)
            elif http_method == 'POST':
                if not event.get('body'):
                    return error_response("Missing request body", headers=headers)
                try:
                    body = json.loads(event['body'])
                    print("Parsed request body:", body)
                except json.JSONDecodeError:
                    return error_response("Invalid JSON in request body", headers=headers)
            else:
                return error_response(f"Unsupported HTTP method: {http_method}", headers=headers)
        else:
            # Handle direct Lambda invocation
            print("Direct Lambda invocation")
            body = event

        # Process the request body (either from API Gateway or direct invocation)
        user_id = body.get('userId')
        token = body.get('token')
        action = body.get('action')
        
        print(f"Processing request - userId: {user_id}, action: {action}")
        
        if not all([user_id, token, action]):
            missing_fields = [f for f in ['userId', 'token', 'action'] 
                            if not body.get(f)]
            return error_response(
                f"Missing required fields: {', '.join(missing_fields)}. Got: {body}",
                headers=headers
            )
        
        if action == 'save':
            return save_token(collection, user_id, token, body.get('platform'), headers)
        elif action == 'remove':
            return remove_token(collection, user_id, token, headers)
        else:
            return error_response(f"Invalid action: {action}", headers=headers)

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")  # Debug log
        return error_response(str(e), headers=headers)

def error_response(message, status_code=400, headers=None):
    if headers is None:
        headers = {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            'Content-Type': 'application/json'
        }
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps({
            'error': True,
            'message': message
        })
    }

def get_user_tokens(collection, user_id, headers):
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
            'headers': headers,
            'body': json.dumps({'tokens': tokens})
        }
    except Exception as e:
        print(f"Error in get_user_tokens: {str(e)}")
        return error_response(f"Failed to get user tokens: {str(e)}", 500, headers)

def save_token(collection, user_id, token, platform, headers):
    try:
        current_time = datetime.utcnow().isoformat()
        print(f"Saving token for user {user_id}")
        
        result = collection.update_one(
            {'_id': user_id},
            {
                '$pull': {'tokens': {'token': token}},
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
        
        print(f"MongoDB update result: {result.modified_count} documents modified")

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'success': True})
        }
    except Exception as e:
        print(f"Error in save_token: {str(e)}")
        return error_response(f"Failed to save token: {str(e)}", 500, headers)

def remove_token(collection, user_id, token, headers):
    try:
        print(f"Removing token for user {user_id}")
        result = collection.update_one(
            {'_id': user_id},
            {'$pull': {'tokens': {'token': token}}}
        )
        
        print(f"MongoDB remove result: {result.modified_count} documents modified")

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'success': True})
        }
    except Exception as e:
        print(f"Error in remove_token: {str(e)}")
        return error_response(f"Failed to remove token: {str(e)}", 500, headers) 