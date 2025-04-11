import json
import os
from pymongo import MongoClient
# Use the bson module that comes with pymongo
from bson.json_util import dumps
from functools import lru_cache
import time

# Create a global MongoDB client with connection pooling
client = MongoClient(
    host=os.environ.get("ATLAS_URI"),
    maxPoolSize=50,  # Adjust based on your needs
    minPoolSize=10,
    connectTimeoutMS=30000,
    socketTimeoutMS=45000
)

# Cache the document for 5 minutes
@lru_cache(maxsize=100)
def get_cached_document(date_str, time_str):
    db = client['padelTimes']
    collection = db['times']
    return collection.find_one({
        'date': date_str,
        'time': time_str
    })

def lambda_handler(event, context):
    # Log the request details for debugging
    print(f"Event: {json.dumps(event)}")
    print(f"Headers: {event.get('headers', {})}")
    print(f"Request context: {event.get('requestContext', {})}")
    
    # Set up CORS headers - make sure these are included in ALL responses
    headers = {
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': '*'
    }
    
    # Handle OPTIONS request (preflight request)
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'CORS preflight request successful'})
        }
    
    try:
        # Extract document ID from query parameters
        params = event.get('queryStringParameters', {}) or {}
        document_id = params.get('documentId')
        
        if not document_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Missing documentId parameter'})
            }
        
        # Parse date and time from document ID (format: YYYYMMDDHHMMSS)
        date_str = f"{document_id[0:4]}-{document_id[4:6]}-{document_id[6:8]}"
        time_str = f"{document_id[8:10]}:{document_id[10:12]}:00"
        
        # Get document from cache or database
        start_time = time.time()
        document = get_cached_document(date_str, time_str)
        query_time = time.time() - start_time
        print(f"Query time: {query_time:.2f} seconds")
        
        if not document:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'Document not found'})
            }
        
        # Use dumps from bson.json_util to properly convert MongoDB types to JSON
        document_json = dumps(document)
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': document_json
        }
        
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 