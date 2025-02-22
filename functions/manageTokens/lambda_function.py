import json
import os
from pymongo import MongoClient
from datetime import datetime, timedelta

def lambda_handler(event, context):
    try:
        print("Received event:", event)  # Debug log
        
        # Handle CORS preflight request
        if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'message': 'OK'})
            }

        client = MongoClient(os.environ.get("ATLAS_URI"))
        if not client:
            return error_response("Failed to connect to database")
            
        db = client['padeltid']
        collection = db['users']

        # Check if this is an API Gateway v2 request
        if 'requestContext' in event and 'http' in event['requestContext']:
            http_method = event['requestContext']['http']['method']
            if http_method == 'GET':
                user_id = event.get('queryStringParameters', {}).get('userId')
                if not user_id:
                    return error_response("Missing userId in GET request")
                return get_user_tokens(collection, user_id)
            elif http_method == 'POST':
                if not event.get('body'):
                    return error_response("Missing request body")
                try:
                    body = json.loads(event['body'])
                except json.JSONDecodeError:
                    return error_response("Invalid JSON in request body")
                print("Request body:", body)
            else:
                return error_response(f"Unsupported HTTP method: {http_method}")
        else:
            # Handle direct Lambda invocation
            body = event

        # Process the request body (either from API Gateway or direct invocation)
        user_id = body.get('userId')
        token = body.get('token')
        action = body.get('action')
        
        if not all([user_id, token, action]):
            missing_fields = [f for f in ['userId', 'token', 'action'] 
                            if not body.get(f)]
            return error_response(
                f"Missing required fields: {', '.join(missing_fields)}. Got: {body}")
        
        if action == 'save':
            return save_token(collection, user_id, token, body.get('platform'))
        elif action == 'remove':
            return remove_token(collection, user_id, token)
        else:
            return error_response(f"Invalid action: {action}")

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")  # Debug log
        return error_response(str(e))

def error_response(message, status_code=400):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({
            'error': True,
            'message': message
        })
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
        return error_response(f"Failed to get user tokens: {str(e)}", 500)

def save_token(collection, user_id, token, platform):
    try:
        current_time = datetime.utcnow().isoformat()
        
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
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'success': True})
        }
    except Exception as e:
        print(f"Error in save_token: {str(e)}")
        return error_response(f"Failed to save token: {str(e)}", 500)

def remove_token(collection, user_id, token):
    try:
        result = collection.update_one(
            {'_id': user_id},
            {'$pull': {'tokens': {'token': token}}}
        )
        
        print(f"MongoDB remove result: {result.modified_count} documents modified")

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
        return error_response(f"Failed to remove token: {str(e)}", 500) 