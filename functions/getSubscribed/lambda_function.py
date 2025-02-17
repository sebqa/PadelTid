import json
import pymongo
from pymongo import MongoClient
import os

def lambda_handler(event, context):
    userId = event['queryStringParameters']['userId']
    host = os.environ.get("ATLAS_URI")

    return get_subscriptions(host, userId)


def get_subscriptions(host, userId):
    client = MongoClient(host)
    db = client['padeltid']
    collection = db['users']
    result = collection.find_one({"_id": userId})
    subscriptions = result['subscriptions']

    return subscriptions

if __name__ == "__main__":
    userId = "2NRANwKZwJU85rrwoQtlIOGNau82"
    print(get_subscriptions("mongodb+srv://padeltidapp:Od7glztEBqiPZ4pn@cluster0.ee9c0x2.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0",userId))