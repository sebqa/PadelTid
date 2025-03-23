import json
import os
from pymongo import MongoClient
from datetime import datetime
from bson import json_util

def lambda_handler(event, context):
    try:
        # Extract document ID from query parameters
        document_id = event['queryStringParameters']['documentId']
        
        # Parse date and time from document ID (format: YYYYMMDDHHMMSS)
        date_str = f"{document_id[0:4]}-{document_id[4:6]}-{document_id[6:8]}"
        time_str = f"{document_id[8:10]}:{document_id[10:12]}:{document_id[12:14]}"
        
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
        
        # Parse it back to a Python dict to add the document ID
        document_dict = json.loads(document_json)
        document_dict['documentId'] = document_id
        
        # Convert clubs data to a more Flutter-friendly format
        if 'clubs' in document_dict:
            for club_name, club_data in document_dict['clubs'].items():
                # Convert available_slots from MongoDB format
                if 'available_slots' in club_data and isinstance(club_data['available_slots'], dict):
                    if '$numberInt' in club_data['available_slots']:
                        club_data['available_slots'] = int(club_data['available_slots']['$numberInt'])
                
                # Convert total_courts from MongoDB format
                if 'total_courts' in club_data and isinstance(club_data['total_courts'], dict):
                    if '$numberInt' in club_data['total_courts']:
                        club_data['total_courts'] = int(club_data['total_courts']['$numberInt'])
                
                # Convert weather data
                if 'weather' in club_data:
                    weather = club_data['weather']
                    # Convert MongoDB number format to simple numbers
                    if 'wind_speed' in weather and isinstance(weather['wind_speed'], dict):
                        if '$numberDouble' in weather['wind_speed']:
                            weather['wind_speed'] = float(weather['wind_speed']['$numberDouble'])
                        elif '$numberInt' in weather['wind_speed']:
                            weather['wind_speed'] = int(weather['wind_speed']['$numberInt'])
                    
                    if 'precipitation_probability' in weather and isinstance(weather['precipitation_probability'], dict):
                        if '$numberDouble' in weather['precipitation_probability']:
                            weather['precipitation_probability'] = float(weather['precipitation_probability']['$numberDouble'])
                        elif '$numberInt' in weather['precipitation_probability']:
                            weather['precipitation_probability'] = int(weather['precipitation_probability']['$numberInt'])
                    
                    if 'air_temperature' in weather and isinstance(weather['air_temperature'], dict):
                        if '$numberDouble' in weather['air_temperature']:
                            weather['air_temperature'] = float(weather['air_temperature']['$numberDouble'])
                        elif '$numberInt' in weather['air_temperature']:
                            weather['air_temperature'] = int(weather['air_temperature']['$numberInt'])
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,GET'
            },
            'body': json.dumps(document_dict)
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