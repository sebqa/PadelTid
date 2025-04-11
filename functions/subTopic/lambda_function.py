import requests, os
import pymongo
from pymongo import MongoClient
import json

def lambda_handler(event, context):
    try:
        date = event["queryStringParameters"]["date"]
        time = event["queryStringParameters"]["time"]
        follow = event["queryStringParameters"]["follow"]
        userId = event["queryStringParameters"]["userId"]
        preferences = event["queryStringParameters"].get("preferences", "{}")  # Get preferences

        # Firebase initialization no longer needed
        return follow_topic(date, time, follow, userId, preferences)
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

def follow_topic(date, time, follow, userId, preferences_str):
    try:
        # Parse device tokens (keeping this in case it's needed elsewhere)        
        # Set up MongoDB connection
        client = MongoClient(os.environ.get("ATLAS_URI"))
        db = client['padeltid']
        collection = db['users']

        date = date.replace("-", "")
        time = time.replace(":", "")
        date_time = date + time

        if follow == "true":
            # Parse preferences from string
            preferences = json.loads(preferences_str)
            
            # Update user's follows - using $set instead of $addToSet
            collection.update_one(
                {
                    "_id": userId,
                    "follows.id": date_time  # Look for existing follow
                },
                {
                    "$set": {
                        "follows.$.preferences": preferences  # Update existing follow
                    }
                }
            )
            
            # If no existing follow was updated, create a new one
            if collection.find_one({"_id": userId, "follows.id": date_time}) is None:
                collection.update_one(
                    {"_id": userId},
                    {
                        "$push": {
                            "follows": {
                                "id": date_time,
                                "preferences": preferences
                            }
                        }
                    },
                    upsert=True
                )
        else:
            # Remove from user's follows
            collection.update_one(
                {"_id": userId}, 
                {"$pull": {"follows": {"id": date_time}}}
            )
            # Clean up empty follow documents
            db.follows.delete_one(
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
                "follow": follow
            })
        }
    except Exception as e:
        print(f"Error in follow_topic: {str(e)}")
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
    print(follow_topic("2024-08-12", "14:00", "false", "bx5jFmFYtRW8v3O8y8EUuuahRho1", "d1bcZ1-ZqgbjBiggC4WLwr:APA91bH25d1DSgYmfS_maO5A-Ft6E3pE-Fp0y89T31SX46j_XR7Ow8I8bCn4eJIsBtl_dvmI4f_uAswGLMrY26RhIQDYmxc6l8ajuII9c-RRGUubLUqt5Z3qcdfua40gPWvBlYr-C4Ol", "{}"))