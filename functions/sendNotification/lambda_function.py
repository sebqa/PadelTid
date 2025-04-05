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
    
    # Create an inverted index of filter criteria that match this document
    matching_criteria = []
    
    # Track ALL court availability changes, not just available ones
    for club_id, club_data in current_doc.get('clubs', {}).items():
        previous_club_data = previous_doc.get('clubs', {}).get(club_id, {})
        
        print(f"Checking club: {club_id}")
        current_slots = club_data.get('available_slots', 0)
        previous_slots = previous_club_data.get('available_slots', 0) if previous_club_data else None
        print(f"Current slots: {current_slots}, Previous slots: {previous_slots}")
        
        # Check if there's been ANY change in availability
        if previous_slots is None or current_slots != previous_slots:
            # Add ALL changes to criteria with availability status
            matching_criteria.append({
                "club_id": club_id,
                "available": current_slots > 0,
                "slots": current_slots,
                "previous_slots": previous_slots,
                "weather": club_data.get('weather', {})
            })
            print(f"Added matching criteria for club {club_id} with {current_slots} slots (previously {previous_slots})")
            print(f"Weather data: {json.dumps(club_data.get('weather', {}))}")
    
    print(f"Total matching criteria found: {len(matching_criteria)}")
    if not matching_criteria:
        print("No matching criteria, skipping user query")
        return 0
        
    total_notifications = 0
    
    # Process users in batches to stay within Lambda memory limits
    batch_size = 100
    processed_users = 0
    
    for skip in range(0, 10000, batch_size):
        query = build_efficient_user_query(matching_criteria, doc_id)
        print(f"MongoDB query (batch {skip//batch_size + 1}): {json.dumps(query)}")
        
        # Use projection to only fetch needed fields
        users_batch = users_collection.find(
            query,
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
            
            print(f"Processing user: {user.get('_id')}")
            user_id = user.get('_id')
            
            # Get the most recent token
            tokens = user.get('tokens', [])
            if not tokens:
                print(f"User {user_id} has no tokens, skipping")
                continue
                
            # Sort tokens by lastUsedAt and get the most recent one
            most_recent_token = max(tokens, key=lambda x: x['lastUsedAt'])
            token = most_recent_token['token']
            
            # Get user preferences
            filter_prefs = user.get('filterPreferences', {})
            show_unavailable = filter_prefs.get('showUnavailableSlots', False)
            
            # Find which club matched the user's criteria
            notification_sent = False
            for match in matching_criteria:
                club_id = match.get("club_id")
                is_available = match.get("available", False)
                slots = match.get("slots", 0)
                previous_slots = match.get("previous_slots")
                
                # Skip this club if user doesn't want to see unavailable courts and court is unavailable
                if not show_unavailable and not is_available:
                    print(f"Skipping unavailable club {club_id} for user {user_id} (showUnavailableSlots=False)")
                    continue
                
                # Check user's location preferences
                if club_id not in filter_prefs.get('locations', []):
                    print(f"Club {club_id} not in user {user_id}'s preferred locations")
                    continue
                
                # Check if weather conditions match user preferences
                if not check_weather_match(match.get("weather", {}), filter_prefs):
                    print(f"Weather conditions for club {club_id} don't match user {user_id}'s preferences")
                    continue
                
                # Craft notification message based on what changed
                notification_body = get_notification_message(is_available, slots, previous_slots)
                
                # Send the notification
                sent = send_notification_to_user(user, token, title, notification_body, doc_id, club_id)
                if sent:
                    total_notifications += 1
                    batch_notifications += 1
                    notification_sent = True
                    print(f"Notification sent to user {user_id} for club {club_id}: {notification_body}")
                    break  # Only send one notification per user
            
            if not notification_sent:
                print(f"No matching clubs found for user {user_id}")
        
        print(f"Batch {skip//batch_size + 1} processed: {batch_count} users, {batch_notifications} notifications sent")
        
        # If we got fewer users than the batch size, we're done
        if batch_count < batch_size:
            print(f"Received fewer users ({batch_count}) than batch size ({batch_size}), stopping pagination")
            break
    
    print(f"Filter notification processing complete. Processed {processed_users} users, sent {total_notifications} notifications")
    return total_notifications

def check_weather_match(weather, filter_prefs):
    """Check if weather conditions match user preferences"""
    # If no weather data, assume it matches
    if not weather:
        return True
        
    # Check wind speed threshold
    if (weather.get('wind_speed') is not None and 
        filter_prefs.get('wind_speed_threshold') is not None and
        weather.get('wind_speed') > filter_prefs.get('wind_speed_threshold')):
        return False
        
    # Check precipitation probability threshold
    if (weather.get('precipitation_probability') is not None and
        filter_prefs.get('precipitation_probability_threshold') is not None and
        weather.get('precipitation_probability') > filter_prefs.get('precipitation_probability_threshold')):
        return False
        
    # Check temperature threshold
    if (weather.get('temperature') is not None and
        filter_prefs.get('temperature_threshold') is not None and
        weather.get('temperature') < filter_prefs.get('temperature_threshold')):
        return False
    
    return True

def get_notification_message(is_available, slots, previous_slots):
    """Generate appropriate notification message based on availability change"""
    if previous_slots is None:
        # New court added
        return "New court added to your preferred location"
    elif not is_available and previous_slots > 0:
        # Court became unavailable
        return "Court is now fully booked"
    elif is_available and previous_slots == 0:
        # Court became available
        return "Court now available matching your preferences"
    elif slots > previous_slots:
        # More courts available
        return f"More courts available now ({slots} slots)"
    elif slots < previous_slots:
        # Fewer courts available
        return f"Courts filling up ({slots} slots remaining)"
    else:
        # Generic message for other changes
        return "Court status updated matching your preferences"

def build_efficient_user_query(matching_criteria, doc_id):
    """Build a query that lets MongoDB do the heavy lifting"""
    
    if not matching_criteria:
        print("No matching criteria provided, returning empty query")
        return {"_id": None}  # Return empty query if no matching criteria
    
    # Base conditions for all users
    base_condition = {
        "filterPreferences.notifyOnMatchingCourts": True,
        "tokens": {"$exists": True, "$ne": []},
        "subscriptions.id": {"$ne": doc_id}  # Not already subscribed to this time slot
    }
    
    # Build location-specific conditions
    club_conditions = []
    for match in matching_criteria:
        club_id = match.get("club_id")
        is_available = match.get("available", False)
        weather = match.get("weather", {})
        
        print(f"Building query condition for club: {club_id} (available: {is_available})")
        
        # Basic club match condition - user must be interested in this location
        club_condition = {
            "filterPreferences.locations": club_id
        }
        
        # Add availability condition based on show_unavailable preference
        if not is_available:
            # For unavailable courts, only include users who want to see unavailable slots
            club_condition["filterPreferences.showUnavailableSlots"] = True
        
        # Add weather threshold conditions if the weather data exists
        weather_conditions = []
        if weather:
            # Wind speed threshold
            if weather.get("wind_speed") is not None:
                print(f"Adding wind speed condition: {weather.get('wind_speed')}")
                club_condition["$or"] = [
                    {"filterPreferences.wind_speed_threshold": {"$exists": False}},
                    {"filterPreferences.wind_speed_threshold": {"$gte": weather.get("wind_speed")}}
                ]
                weather_conditions.append(f"wind_speed <= {weather.get('wind_speed')}")
            
            # Precipitation probability threshold
            if weather.get("precipitation_probability") is not None:
                print(f"Adding precipitation condition: {weather.get('precipitation_probability')}")
                club_condition["$or"] = club_condition.get("$or", []) + [
                    {"filterPreferences.precipitation_probability_threshold": {"$exists": False}},
                    {"filterPreferences.precipitation_probability_threshold": {"$gte": weather.get("precipitation_probability")}}
                ]
                weather_conditions.append(f"precip <= {weather.get('precipitation_probability')}")
            
            # Temperature threshold
            if weather.get("temperature") is not None:
                print(f"Adding temperature condition: {weather.get('temperature')}")
                club_condition["$or"] = club_condition.get("$or", []) + [
                    {"filterPreferences.temperature_threshold": {"$exists": False}},
                    {"filterPreferences.temperature_threshold": {"$lte": weather.get("temperature")}}
                ]
                weather_conditions.append(f"temp >= {weather.get('temperature')}")
        
        print(f"Club {club_id} condition with weather checks: {', '.join(weather_conditions) if weather_conditions else 'No weather checks'}")
        club_conditions.append(club_condition)
    
    # Combine with OR - user matches if any of the club conditions match
    if club_conditions:
        base_condition["$or"] = club_conditions
    
    return base_condition

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

