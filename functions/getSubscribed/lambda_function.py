import json
import os
from pymongo import MongoClient

def lambda_handler(event, context):
    try:
        userId = event['queryStringParameters']['userId']
        host = os.environ.get("ATLAS_URI")
        return get_subscriptions(host, userId)
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_subscriptions(host, userId):
    client = MongoClient(host=host)
    db = client['padeltid']
    result = db['users'].find_one({'_id': userId})
    
    # Handle case where user doesn't exist or has no subscriptions
    if not result:
        print(f"No user found for ID: {userId}")
        return format_response([])
        
    subscriptions = result.get('subscriptions', [])
    print(f"Found subscriptions for user {userId}: {subscriptions}")
    
    return format_response(subscriptions)

def format_response(subscriptions):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps(subscriptions)
    }

if __name__ == "__main__":
    userId = "2NRANwKZwJU85rrwoQtlIOGNau82"
    print(get_subscriptions("mongodb+srv://padeltidapp:Od7glztEBqiPZ4pn@cluster0.ee9c0x2.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0",userId))