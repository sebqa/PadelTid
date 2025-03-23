import json
import os
from pymongo import MongoClient
from bson import json_util

def lambda_handler(event, context):
    try:
        # Extract document ID from query parameters
        document_id = event['queryStringParameters']['documentId']
        
        # Parse date and time from document ID (format: YYYYMMDDHHMMSS)
        date_str = f"{document_id[0:4]}-{document_id[4:6]}-{document_id[6:8]}"
        time_str = f"{document_id[8:10]}:{document_id[10:12]}:00}"
        
        # Connect to MongoDB
        client = MongoClient(host=os.environ.get("ATLAS_URI"))
        db = client['padelTimes']
        collection = db['times']
        
        # Query for the document
        document = collection.find_one({
            'date': date_str,
            'time': time_str
        })
        
        if not document:
            return {
                'statusCode': 404,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,GET'
                },
                'body': json.dumps({'error': 'Document not found'})
            }
        
        # Use json_util to properly convert MongoDB types to JSON
        document_json = json_util.dumps(document)
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,GET'
            },
            'body': document_json
        }
        
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,GET'
            },
            'body': json.dumps({'error': str(e)})
        } 