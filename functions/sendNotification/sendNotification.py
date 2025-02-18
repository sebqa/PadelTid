#Use FCM to send a notification to a topic

import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging
import requests, os
import pymongo
from pymongo import MongoClient
from datetime import datetime, timedelta

cred = credentials.Certificate("credentials/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

def lambda_handler(event, context):
    return send_notification(event)


def send_notification(event):
    #if available slots changes from something to 0
    title = "Test"
    body = "Test body"
    date = event['detail']['fullDocument']['date']
    time = event['detail']['fullDocument']['time']

    #if date is today and time is two hours before now, then delete document and remove subscription
    current_time = datetime.now()
    current_time = current_time.strftime("%Y-%m-%d %H:%M:%S")

    if date == current_time[:10] and time < (current_time[11:16] - timedelta(hours=2)):
        

    topic = date.replace("-", "")+time.replace(":", "")
    if event['detail']['fullDocumentBeforeChange']['available_slots'] == 0 and event['detail']['fullDocument']['available_slots'] > 0:
        title = date.split('-')[2] + "/"+ date.split('-')[1]+" "+time[:5]
        body = "Der er ledige tider"
    if event['detail']['fullDocument']['available_slots'] == 0 and event['detail']['fullDocumentBeforeChange']['available_slots'] > 0:
        title = date.split('-')[2] + "/"+ date.split('-')[1]+" "+time[:5]
        body = "Der er ikke flere ledige tider"

    # See documentation on defining a message payload.
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        topic=topic,
    )

    # Send the message
    response = messaging.send(message)
    # Response is a message ID string.
    print('Successfully sent message:', response)
    print('Topic: '+topic)
    return response




if __name__ == '__main__':

    send_notification(event)

