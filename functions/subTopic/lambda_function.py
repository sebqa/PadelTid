import requests, os
import pymongo
from pymongo import MongoClient
import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging
import json

# Initialize Firebase Admin SDK only if not already initialized
def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": os.environ.get("FIREBASE_PROJECT_ID"),
            "private_key_id": os.environ.get("FIREBASE_PRIVATE_KEY_ID"),
            "private_key": os.environ.get("FIREBASE_PRIVATE_KEY").replace('\\n', '\n'),
            "client_email": os.environ.get("FIREBASE_CLIENT_EMAIL"),
            "client_id": os.environ.get("FIREBASE_CLIENT_ID"),
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url": os.environ.get("FIREBASE_CLIENT_CERT_URL")
        })
        firebase_admin.initialize_app(cred)

def lambda_handler(event, context):
    try:
        date = event["queryStringParameters"]["date"]
        time = event["queryStringParameters"]["time"]
        device_token = event["queryStringParameters"]["device_token"]
        subscribe = event["queryStringParameters"]["subscribe"]
        userId = event["queryStringParameters"]["userId"]

        initialize_firebase()
        return subscribe_to_topic(date, time, subscribe, userId, device_token)
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

def subscribe_to_topic(date, time, subscribe, userId, device_token):
    try:
        # Set up MongoDB connection
        client = MongoClient(os.environ.get("ATLAS_URI"))
        db = client['padeltid']
        collection = db['users']

        date = date.replace("-", "")
        time = time.replace(":", "")
        date_time = date + time

        if subscribe == "true":
            # Update user's subscriptions
            collection.update_one(
                {"_id": userId}, 
                {"$addToSet": {"subscriptions": date_time}}, 
                upsert=True
            )
            
            # Update or create subscription document
            db.subscriptions.update_one(
                {"_id": date_time},
                {"$addToSet": {"users": userId}},
                upsert=True
            )
            
            # Subscribe to Firebase topic
            response = messaging.subscribe_to_topic([device_token], date_time)
        else:
            # Remove from user's subscriptions
            collection.update_one(
                {"_id": userId}, 
                {"$pull": {"subscriptions": date_time}}
            )
            
            # Remove user from subscription document
            db.subscriptions.update_one(
                {"_id": date_time},
                {"$pull": {"users": userId}}
            )
            
            # Clean up empty subscription documents
            db.subscriptions.delete_one(
                {"_id": date_time, "users": {"$size": 0}}
            )
            
            # Unsubscribe from Firebase topic
            response = messaging.unsubscribe_from_topic([device_token], date_time)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                "updatedCount": str(response.success_count),
                "subscribe": subscribe
            })
        }
    except Exception as e:
        print(f"Error in subscribe_to_topic: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        }

if __name__ == "__main__":
    print(subscribe_to_topic("2024-08-12", "14:00", "false", "bx5jFmFYtRW8v3O8y8EUuuahRho1", "d1bcZ1-ZqgbjBiggC4WLwr:APA91bH25d1DSgYmfS_maO5A-Ft6E3pE-Fp0y89T31SX46j_XR7Ow8I8bCn4eJIsBtl_dvmI4f_uAswGLMrY26RhIQDYmxc6l8ajuII9c-RRGUubLUqt5Z3qcdfua40gPWvBlYr-C4Ol"))