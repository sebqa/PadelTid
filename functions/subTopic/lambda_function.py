import requests, os
import pymongo
from pymongo import MongoClient
import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging

cred = credentials.Certificate("credentials/serviceAccountKey.json")
firebase_admin.initialize_app(cred)
import json


def lambda_handler(event, context):
    date = event["queryStringParameters"]["date"]
    time = event["queryStringParameters"]["time"]
    device_token = event["queryStringParameters"]["device_token"]
    #bool. to subscribe or not
    subscribe = event["queryStringParameters"]["subscribe"]
    userId = event["queryStringParameters"]["userId"]

    return subscribe_to_topic(date, time, subscribe, userId, device_token)


def subscribe_to_topic(date, time, subscribe, userId, device_token):
    # Set up MongoDB connection
    client = MongoClient("mongodb+srv://padeltidapp:Od7glztEBqiPZ4pn@cluster0.ee9c0x2.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
    db = client['padeltid']
    collection = db['users']

    response = ""
    date = date.replace("-", "")
    time = time.replace(":", "")
    date_time = date+time
    if subscribe == "true":
        collection.update_one({"_id": userId}, {"$addToSet": {"subscriptions": date_time}}, upsert=True)
        db.subscriptions.insert_one({"_id": date_time, "users": [userId]})
        response = messaging.subscribe_to_topic([device_token], date_time)
    else:
        collection.update_one({"_id": userId}, {"$pull": {"subscriptions": date_time}})
        db.subscriptions.delete_one({"_id": date_time})
        response = messaging.unsubscribe_from_topic([device_token], date_time)

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({"updatedCount":str(response.success_count),"subscribe":subscribe})
    }

if __name__ == "__main__":
    print(subscribe_to_topic("2024-08-12", "14:00", "false", "bx5jFmFYtRW8v3O8y8EUuuahRho1", "d1bcZ1-ZqgbjBiggC4WLwr:APA91bH25d1DSgYmfS_maO5A-Ft6E3pE-Fp0y89T31SX46j_XR7Ow8I8bCn4eJIsBtl_dvmI4f_uAswGLMrY26RhIQDYmxc6l8ajuII9c-RRGUubLUqt5Z3qcdfua40gPWvBlYr-C4Ol"))