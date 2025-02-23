import requests, os
import pymongo
from pymongo import MongoClient
import json

def lambda_handler(event, context):
    try:
        date = event["queryStringParameters"]["date"]
        time = event["queryStringParameters"]["time"]
        device_tokens = event["queryStringParameters"]["device_tokens"]
        subscribe = event["queryStringParameters"]["subscribe"]
        userId = event["queryStringParameters"]["userId"]
        preferences = event["queryStringParameters"].get("preferences", "{}")  # Get preferences

        # Firebase initialization no longer needed
        return subscribe_to_topic(date, time, subscribe, userId, device_tokens, preferences)
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

def subscribe_to_topic(date, time, subscribe, userId, device_tokens_str, preferences_str):
    try:
        # Parse device tokens (keeping this in case it's needed elsewhere)
        device_tokens = json.loads(device_tokens_str)
        
        # Set up MongoDB connection
        client = MongoClient(os.environ.get("ATLAS_URI"))
        db = client['padeltid']
        collection = db['users']

        date = date.replace("-", "")
        time = time.replace(":", "")
        date_time = date + time

        if subscribe == "true":
            # Parse preferences from string
            preferences = json.loads(preferences_str)
            
            # Update user's subscriptions - using $set instead of $addToSet
            collection.update_one(
                {
                    "_id": userId,
                    "subscriptions.id": date_time  # Look for existing subscription
                },
                {
                    "$set": {
                        "subscriptions.$.preferences": preferences  # Update existing subscription
                    }
                }
            )
            
            # If no existing subscription was updated, create a new one
            if collection.find_one({"_id": userId, "subscriptions.id": date_time}) is None:
                collection.update_one(
                    {"_id": userId},
                    {
                        "$push": {
                            "subscriptions": {
                                "id": date_time,
                                "preferences": preferences
                            }
                        }
                    },
                    upsert=True
                )
            
            # Update subscription document
            db.subscriptions.update_one(
                {"_id": date_time},
                {
                    "$addToSet": {"users": userId},
                    "$set": {f"preferences.{userId}": preferences}
                },
                upsert=True
            )
        else:
            # Remove from user's subscriptions
            collection.update_one(
                {"_id": userId}, 
                {"$pull": {"subscriptions": {"id": date_time}}}
            )
            
            # Remove user from subscription document
            db.subscriptions.update_one(
                {"_id": date_time},
                {
                    "$pull": {"users": userId},
                    "$unset": {f"preferences.{userId}": ""}
                }
            )
            
            # Clean up empty subscription documents
            db.subscriptions.delete_one(
                {"_id": date_time, "users": {"$size": 0}}
            )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                "success": True,
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
    print(subscribe_to_topic("2024-08-12", "14:00", "false", "bx5jFmFYtRW8v3O8y8EUuuahRho1", "d1bcZ1-ZqgbjBiggC4WLwr:APA91bH25d1DSgYmfS_maO5A-Ft6E3pE-Fp0y89T31SX46j_XR7Ow8I8bCn4eJIsBtl_dvmI4f_uAswGLMrY26RhIQDYmxc6l8ajuII9c-RRGUubLUqt5Z3qcdfua40gPWvBlYr-C4Ol", "{}"))