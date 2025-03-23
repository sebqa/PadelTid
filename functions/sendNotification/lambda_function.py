#Use FCM to send a notification to a topic

import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging
import requests, os
import pymongo
from pymongo import MongoClient
from datetime import datetime, timedelta
import json

# Initialize Firebase Admin SDK only if not already initialized
def initialize_firebase():
    try:
        if not firebase_admin._apps:
            # Log the project ID to verify we're using the correct credentials
            project_id = os.environ.get("FIREBASE_PROJECT_ID")
            print(f"Initializing Firebase with project ID: {project_id}")
            
            private_key = os.environ.get("FIREBASE_PRIVATE_KEY", "").replace('\\n', '\n')
            
            cred = credentials.Certificate({
                "type": "service_account",
                "project_id": project_id,
                "private_key_id": os.environ.get("FIREBASE_PRIVATE_KEY_ID"),
                "private_key": private_key,
                "client_email": os.environ.get("FIREBASE_CLIENT_EMAIL"),
                "client_id": os.environ.get("FIREBASE_CLIENT_ID"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": os.environ.get("FIREBASE_CLIENT_CERT_URL")
            })
            
            try:
                firebase_admin.initialize_app(cred)
                print("Firebase Admin SDK initialized successfully")
            except Exception as init_error:
                print(f"Error initializing Firebase: {str(init_error)}")
                raise
    except Exception as e:
        print(f"Error in initialize_firebase: {str(e)}")
        print(f"Available environment variables: {[k for k in os.environ.keys() if 'FIREBASE' in k]}")
        raise

def lambda_handler(event, context):
    # Initialize Firebase before sending notifications
    initialize_firebase()
    return send_notification(event)

def send_notification(event):
    date = event['detail']['fullDocument']['date']
    time = event['detail']['fullDocument']['time']
    doc_id = date.replace("-", "") + time.replace(":", "")
    
    # Get current and previous states
    current_doc = event['detail']['fullDocument']
    previous_doc = event['detail'].get('fullDocumentBeforeChange', {})
    
    # Initialize notification data
    title = date.split('-')[2] + "/" + date.split('-')[1] + " " + time[:5]
    
    # Connect to MongoDB
    client = MongoClient(os.environ['ATLAS_URI'])
    db = client.padeltid
    users_collection = db.users

    # Find all users subscribed to this time slot
    users = users_collection.find({
        "subscriptions": {
            "$elemMatch": {
                "id": doc_id
            }
        }
    })

    notifications_sent = 0
    
    for user in users:
        # Get the user's preferences for this time slot
        subscription = next(
            (sub for sub in user['subscriptions'] if sub['id'] == doc_id), 
            None
        )
        if not subscription or not subscription.get('preferences'):
            continue

        preferences = subscription['preferences']
        
        # Get the most recent token
        tokens = user.get('tokens', [])
        if not tokens:
            continue
            
        # Sort tokens by lastUsedAt and get the most recent one
        most_recent_token = max(tokens, key=lambda x: x['lastUsedAt'])
        token = most_recent_token['token']

        # Check conditions and send appropriate notifications
        for club_id, club_data in current_doc.get('clubs', {}).items():
            previous_club_data = previous_doc.get('clubs', {}).get(club_id, {})
            
            current_weather = club_data.get('weather', {})
            previous_weather = previous_club_data.get('weather', {})
            
            current_slots = club_data.get('available_slots', 0)
            previous_slots = previous_club_data.get('available_slots', 0)
            
            notification_body = None
            
            # Check weather changes
            if (preferences.get('notifyOnWeatherChange') and 
                previous_weather and 
                current_weather.get('symbol_code') != previous_weather.get('symbol_code')):
                notification_body = f"Weather changed to {current_weather.get('symbol_code')}"
            
            # Check availability changes
            elif preferences.get('notifyWhenAvailable') and previous_slots == 0 and current_slots > 0:
                notification_body = "Courts now available"
            
            # Check when only one court is left
            elif preferences.get('notifyWhenOneLeft') and previous_slots > 1 and current_slots == 1:
                notification_body = "Only one court left"
            
            # Check when courts become full
            elif preferences.get('notifyWhenFull') and previous_slots > 0 and current_slots == 0:
                notification_body = "No more available courts"
            
            if notification_body:
                # Create document ID from date and time
                date_no_dashes = date.replace('-', '')
                time_no_colons = time.replace(':', '')
                doc_id = f"{date_no_dashes}{time_no_colons}"
                
                # Send notification to this specific user with just the document ID
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=notification_body
                    ),
                    data={
                        "documentId": doc_id,
                        "click_action": "FLUTTER_NOTIFICATION_CLICK",
                        "club_id": club_id
                    },
                    token=token
                )
                
                try:
                    response = messaging.send(message)
                    print(f'Successfully sent message to user {user["_id"]}: {response}')
                    notifications_sent += 1
                    break  # Break after sending first applicable notification
                except Exception as e:
                    print(f'Failed to send message to user {user["_id"]}: {str(e)}')

    client.close()
    return f"Sent {notifications_sent} notifications"




if __name__ == '__main__':

    send_notification(event)

