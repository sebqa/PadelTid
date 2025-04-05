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
    print(f"Starting notification processing for event: {json.dumps(event.get('detail', {}).get('operationType', 'unknown'))}")
    date = event['detail']['fullDocument']['date']
    time = event['detail']['fullDocument']['time']
    doc_id = date.replace("-", "") + time.replace(":", "")
    
    print(f"Processing document: {doc_id} (date: {date}, time: {time})")
    
    # Get current and previous states
    current_doc = event['detail']['fullDocument']
    previous_doc = event['detail'].get('fullDocumentBeforeChange', {})
    
    # Initialize notification data
    title = date.split('-')[2] + "/" + date.split('-')[1] + " " + time[:5]
    
    # Connect to MongoDB
    client = MongoClient(os.environ['ATLAS_URI'])
    db = client.padeltid
    users_collection = db.users

    notifications_sent = 0
    
    # Process users with subscriptions for this time slot
    print("Processing subscription-based notifications...")
    subscription_notifications = process_subscribed_users(users_collection, doc_id, current_doc, previous_doc, title)
    notifications_sent += subscription_notifications
    print(f"Subscription notifications sent: {subscription_notifications}")
    
    # Process users with matching court filters
    print("Processing filter-based notifications...")
    filter_notifications = process_filter_matching_users(users_collection, doc_id, current_doc, previous_doc, title, date, time)
    notifications_sent += filter_notifications
    print(f"Filter-based notifications sent: {filter_notifications}")

    client.close()
    print(f"Notification processing complete. Total sent: {notifications_sent}")
    return f"Sent {notifications_sent} notifications"

def process_subscribed_users(users_collection, doc_id, current_doc, previous_doc, title):
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
                sent = send_notification_to_user(user, token, title, notification_body, doc_id, club_id)
                if sent:
                    notifications_sent += 1
                    break  # Break after sending first applicable notification

    return notifications_sent

def process_filter_matching_users(users_collection, doc_id, current_doc, previous_doc, title, date, time):
    print(f"Starting filter-based notification processing for doc_id: {doc_id}")
    
    # Skip if no previous document (new document won't have changed state)
    if not previous_doc:
        print("No previous document state, skipping filter notifications")
        return 0
    
    total_notifications = 0
    
    # Get all users with notifyOnMatchingCourts enabled (with batching)
    batch_size = 100
    processed_users = 0
    
    for skip in range(0, 10000, batch_size):
        # Find users who have notifications enabled and at least one token
        users_batch = users_collection.find(
            {
                "filterPreferences.notifyOnMatchingCourts": True,
                "tokens": {"$exists": True, "$ne": []},
                "subscriptions.id": {"$ne": doc_id}  # Not already subscribed
            },
            projection={
                "_id": 1, 
                "tokens": 1, 
                "filterPreferences": 1
            }
        ).skip(skip).limit(batch_size)
        
        batch_count = 0
        batch_notifications = 0
        
        for user in users_batch:
            batch_count += 1
            processed_users += 1
            user_id = user.get('_id')
            print(f"Processing user: {user_id}")
            
            # Get user preferences
            filter_prefs = user.get('filterPreferences', {})
            # Add user_id to preferences for logging purposes
            filter_prefs['_user_id'] = user_id
            show_unavailable = filter_prefs.get('showUnavailableSlots', False)
            
            # Get their token
            tokens = user.get('tokens', [])
            if not tokens:
                print(f"User {user_id} has no tokens, skipping")
                continue
                
            # Get the most recent token
            most_recent_token = max(tokens, key=lambda x: x['lastUsedAt'])
            token = most_recent_token['token']
            
            # Check each club the user is interested in
            for club_id in filter_prefs.get('locations', []):
                # Get current and previous club data
                current_club_data = current_doc.get('clubs', {}).get(club_id, {})
                previous_club_data = previous_doc.get('clubs', {}).get(club_id, {})
                
                if current_club_data:
                    current_club_data['club_id'] = club_id
                if previous_club_data:
                    previous_club_data['club_id'] = club_id
                
                # Skip if no data for this club
                if not current_club_data or not previous_club_data:
                    print(f"Missing data for club {club_id}, skipping")
                    continue
                
                # Check availability
                current_available = current_club_data.get('available_slots', 0) > 0
                
                # Skip unavailable courts if user doesn't want to see them
                if not current_available and not show_unavailable:
                    print(f"Skipping unavailable club {club_id} (showUnavailableSlots=False)")
                    continue
                
                # Check if the court previously matched the user's filter
                previous_match = check_filter_match(previous_club_data, filter_prefs)
                
                # Check if the court currently matches the user's filter
                current_match = check_filter_match(current_club_data, filter_prefs)
                
                print(f"Club {club_id} for user {user_id}: Previous match: {previous_match}, Current match: {current_match}")
                
                # Only notify if the court previously didn't match but now does
                if not previous_match and current_match:
                    notification_body = "New court matches your filter criteria"
                    print(f"Sending notification for club {club_id} to user {user_id}")
                    
                    sent = send_notification_to_user(user, token, title, notification_body, doc_id, club_id)
                    if sent:
                        total_notifications += 1
                        batch_notifications += 1
                        break  # Only send one notification per user
            
        print(f"Batch {skip//batch_size + 1} processed: {batch_count} users, {batch_notifications} notifications sent")
        
        # If we got fewer users than the batch size, we're done
        if batch_count < batch_size:
            break
    
    print(f"Filter notification processing complete. Processed {processed_users} users, sent {total_notifications} notifications")
    return total_notifications

def check_filter_match(club_data, filter_prefs):
    """Check if club data matches user filter preferences"""
    user_id = filter_prefs.get('_user_id', 'unknown')  # For logging purposes
    club_id = club_data.get('club_id', 'unknown')
    
    print(f"Checking filter match for club {club_id} against user {user_id} preferences")
    
    # Check availability first
    available_slots = club_data.get('available_slots', 0)
    show_unavailable = filter_prefs.get('showUnavailableSlots', False)
    
    print(f"  Availability check: slots={available_slots}, showUnavailable={show_unavailable}")
    if available_slots == 0 and not show_unavailable:
        print(f"  ❌ Availability check failed: Court has no slots and user doesn't want to see unavailable courts")
        return False
    else:
        print(f"  ✅ Availability check passed")
    
    # Get weather data
    weather = club_data.get('weather', {})
    if not weather:
        print(f"  ℹ️ No weather data available, skipping weather checks")
        return True  # No weather data means we can't filter on it
    
    print(f"  Weather data: {json.dumps(weather)}")
    print(f"  User thresholds: wind={filter_prefs.get('wind_threshold')}, " +
          f"precip={filter_prefs.get('precip_threshold')}, " +
          f"temp={filter_prefs.get('min_temp')}")
    
    # Check wind speed threshold
    if weather.get('wind_speed') is not None and filter_prefs.get('wind_threshold') is not None:
        wind_speed = weather.get('wind_speed')
        threshold = filter_prefs.get('wind_threshold')
        print(f"  Wind check: current={wind_speed}, threshold={threshold}")
        
        if wind_speed > threshold:
            print(f"  ❌ Wind check failed: {wind_speed} > {threshold}")
            return False
        else:
            print(f"  ✅ Wind check passed: {wind_speed} <= {threshold}")
    else:
        print(f"  ℹ️ Skipping wind check - missing data")
    
    # Check precipitation probability threshold
    if weather.get('precipitation_probability') is not None and filter_prefs.get('precip_threshold') is not None:
        precip = weather.get('precipitation_probability')
        threshold = filter_prefs.get('precip_threshold')
        print(f"  Precipitation check: current={precip}, threshold={threshold}")
        
        if precip > threshold:
            print(f"  ❌ Precipitation check failed: {precip} > {threshold}")
            return False
        else:
            print(f"  ✅ Precipitation check passed: {precip} <= {threshold}")
    else:
        print(f"  ℹ️ Skipping precipitation check - missing data")
    
    # Check temperature threshold
    if weather.get('temperature') is not None and filter_prefs.get('min_temp') is not None:
        temp = weather.get('temperature')
        threshold = filter_prefs.get('min_temp')
        print(f"  Temperature check: current={temp}, threshold={threshold}")
        
        if temp < threshold:
            print(f"  ❌ Temperature check failed: {temp} < {threshold}")
            return False
        else:
            print(f"  ✅ Temperature check passed: {temp} >= {threshold}")
    else:
        print(f"  ℹ️ Skipping temperature check - missing data")
    
    # If we passed all checks, it's a match
    print(f"  🎯 All checks passed - MATCH FOUND")
    return True

def send_notification_to_user(user, token, title, body, doc_id, club_id):
    print(f"Preparing to send notification to {user.get('_id')}: {title} - {body}")
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
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
        return True
    except Exception as e:
        print(f'Failed to send message to user {user["_id"]}: {str(e)}')
        print(f'Token used: {token[:10]}...{token[-5:]}')  # Log partial token for debugging
        return False

if __name__ == '__main__':
    send_notification(event)

