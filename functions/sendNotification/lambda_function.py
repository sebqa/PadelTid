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
    
    # Check if the event is in the past
    try:
        event_datetime = datetime.strptime(f"{date} {time}", "%Y-%m-%d %H:%M:%S")
        current_datetime = datetime.now()
        
        if event_datetime < current_datetime:
            print(f"Ignoring past event: {date} {time} is earlier than current time {current_datetime}")
            return "Ignored past event"
    except Exception as e:
        print(f"Error checking event datetime: {str(e)}")
        # Continue processing if we can't parse the datetime
    
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
    
    # Process users with follows for this time slot
    print("Processing follow-based notifications...")
    follow_notifications = process_followed_users(users_collection, doc_id, current_doc, previous_doc, title)
    notifications_sent += follow_notifications
    print(f"Follow notifications sent: {follow_notifications}")
    
    # Process users with matching court filters
    print("Processing filter-based notifications...")
    filter_notifications = process_filter_matching_users(users_collection, doc_id, current_doc, previous_doc, title, date, time)
    notifications_sent += filter_notifications
    print(f"Filter-based notifications sent: {filter_notifications}")

    client.close()
    print(f"Notification processing complete. Total sent: {notifications_sent}")
    return f"Sent {notifications_sent} notifications"

def process_followed_users(users_collection, doc_id, current_doc, previous_doc, title):
    # Find all users following this time slot
    users = users_collection.find({
        "follows": {
            "$elemMatch": {
                "id": doc_id
            }
        }
    })

    notifications_sent = 0
    
    for user in users:
        # Get the user's preferences for this time slot
        follow = next(
            (follow for follow in user['follows'] if follow['id'] == doc_id), 
            None
        )
        if not follow or not follow.get('preferences'):
            continue

        preferences = follow['preferences']
        
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
    
    # Process each club that has changed and find users with relevant preferences
    for club_id, current_club_data in current_doc.get('clubs', {}).items():
        previous_club_data = previous_doc.get('clubs', {}).get(club_id, {})
        
        # Skip if no previous data for comparison
        if not previous_club_data:
            continue
            
        current_club_data['club_id'] = club_id
        previous_club_data['club_id'] = club_id
        
        print(f"Processing club {club_id}")
        
        # Get current weather data for this club
        current_weather = current_club_data.get('weather', {})
        current_slots = current_club_data.get('available_slots', 0)
        
        if not current_weather:
            print(f"No weather data for club {club_id}, skipping")
            continue
            
        wind_speed = current_weather.get('wind_speed')
        precip_prob = current_weather.get('precipitation_probability')
        temperature = current_weather.get('air_temperature')
        
        # Build weather-based query conditions - ALL thresholds must be met
        weather_and_conditions = []
        
        # Handle wind speed thresholds
        if wind_speed is not None:
            weather_and_conditions.append({
                "$or": [
                    {f"filterPreferences.locationPreferences.{club_id}.wind_threshold": {"$gte": wind_speed}},
                    {"filterPreferences.wind_speed_threshold": {"$gte": wind_speed}},
                    {"filterPreferences.wind_speed_threshold": {"$exists": False}}  # No threshold set
                ]
            })
        
        # Handle precipitation thresholds
        if precip_prob is not None:
            weather_and_conditions.append({
                "$or": [
                    {f"filterPreferences.locationPreferences.{club_id}.precip_threshold": {"$gte": precip_prob}},
                    {"filterPreferences.precipitation_probability_threshold": {"$gte": precip_prob}},
                    {"filterPreferences.precipitation_probability_threshold": {"$exists": False}}  # No threshold set
                ]
            })
        
        # Handle temperature thresholds
        if temperature is not None:
            weather_and_conditions.append({
                "$or": [
                    {f"filterPreferences.locationPreferences.{club_id}.min_temp": {"$lte": temperature}},
                    {"filterPreferences.temperature_threshold": {"$lte": temperature}},
                    {"filterPreferences.temperature_threshold": {"$exists": False}}  # No threshold set
                ]
            })
        
        # Handle availability preferences
        availability_condition = None
        if current_slots == 0:
            # Only users who want to see unavailable slots
            availability_condition = {"filterPreferences.showUnavailableSlots": True}
        else:
            # Users who want available slots OR users who want to see unavailable slots
            availability_condition = {
                "$or": [
                    {"filterPreferences.showUnavailableSlots": {"$ne": False}},
                    {"filterPreferences.showUnavailableSlots": {"$exists": False}}  # Default behavior
                ]
            }
        
        # Build the complete query
        query = {
            "filterPreferences.notifyOnMatchingCourts": True,
            "filterPreferences.locations": club_id,
            "tokens": {"$exists": True, "$ne": []},
            "follows.id": {"$ne": doc_id}  # Not already following
        }
        
        # Add all conditions using $and - ALL must be met
        and_conditions = []
        and_conditions.extend(weather_and_conditions)  # All weather conditions must be met
        if availability_condition:
            and_conditions.append(availability_condition)
        
        if and_conditions:
            query["$and"] = and_conditions
        
        print(f"Query for club {club_id}: {query}")
        
        # Get users who match the weather/availability criteria for this club
        club_users = users_collection.find(
            query,
            projection={
                "_id": 1, 
                "tokens": 1, 
                "filterPreferences": 1
            }
        )
        
        club_notifications = 0
        users_processed = 0
        
        for user in club_users:
            users_processed += 1
            user_id = user.get('_id')
            
            # Get user preferences
            filter_prefs = user.get('filterPreferences', {})
            filter_prefs['_user_id'] = user_id
            
            # Get their token
            tokens = user.get('tokens', [])
            if not tokens:
                continue
                
            most_recent_token = max(tokens, key=lambda x: x['lastUsedAt'])
            token = most_recent_token['token']
            
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
                    club_notifications += 1
        
        print(f"Club {club_id}: Processed {users_processed} users, sent {club_notifications} notifications")
    
    print(f"Filter notification processing complete. Total sent: {total_notifications}")
    return total_notifications

def check_filter_match(club_data, filter_prefs):
    """Check if club data matches user filter preferences"""
    user_id = filter_prefs.get('_user_id', 'unknown')  # For logging purposes
    club_id = club_data.get('club_id', 'unknown')
    
    print(f"Checking filter match for club {club_id} against user {user_id} preferences")
    print(f"  Full filter preferences: {json.dumps(filter_prefs)}")
    # Check availability first - return False if available_slots is not present
    available_slots = club_data.get('available_slots')
    if available_slots is None:
        print(f"  ❌ Availability check failed: available_slots attribute not present")
        return False
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
    
    # Handle both optimized structure (nested under locationPreferences) and original structure
    wind_threshold = None
    precip_threshold = None
    temp_threshold = None
    
    # Try optimized structure first
    location_prefs = filter_prefs.get('locationPreferences', {}).get(club_id, {})
    if location_prefs:
        wind_threshold = location_prefs.get('wind_threshold')
        precip_threshold = location_prefs.get('precip_threshold')
        temp_threshold = location_prefs.get('min_temp')
        print(f"  Using location-specific preferences for club {club_id}")
    
    # Fall back to original structure if needed
    if wind_threshold is None:
        wind_threshold = filter_prefs.get('wind_speed_threshold')
        if isinstance(wind_threshold, dict) and '$numberDouble' in wind_threshold:
            wind_threshold = float(wind_threshold.get('$numberDouble'))
    
    if precip_threshold is None:
        precip_threshold = filter_prefs.get('precipitation_probability_threshold')
        if isinstance(precip_threshold, dict) and '$numberDouble' in precip_threshold:
            precip_threshold = float(precip_threshold.get('$numberDouble'))
    
    if temp_threshold is None:
        temp_threshold = filter_prefs.get('temperature_threshold')
        if isinstance(temp_threshold, dict) and '$numberDouble' in temp_threshold:
            temp_threshold = float(temp_threshold.get('$numberDouble'))
    
    print(f"  User thresholds: wind={wind_threshold}, precip={precip_threshold}, temp={temp_threshold}")
    
    # Check wind speed threshold
    if weather.get('wind_speed') is not None and wind_threshold is not None:
        wind_speed = weather.get('wind_speed')
        threshold = wind_threshold
        print(f"  Wind check: current={wind_speed}, threshold={threshold}")
        
        if wind_speed > threshold:
            print(f"  ❌ Wind check failed: {wind_speed} > {threshold}")
            return False
        else:
            print(f"  ✅ Wind check passed: {wind_speed} <= {threshold}")
    else:
        print(f"  ℹ️ Skipping wind check - missing data")
    
    # Check precipitation probability threshold
    if weather.get('precipitation_probability') is not None and precip_threshold is not None:
        precip = weather.get('precipitation_probability')
        threshold = precip_threshold
        print(f"  Precipitation check: current={precip}, threshold={threshold}")
        
        if precip > threshold:
            print(f"  ❌ Precipitation check failed: {precip} > {threshold}")
            return False
        else:
            print(f"  ✅ Precipitation check passed: {precip} <= {threshold}")
    else:
        print(f"  ℹ️ Skipping precipitation check - missing data")
    
    # Check temperature threshold
    if weather.get('air_temperature') is not None and temp_threshold is not None:
        temp = weather.get('air_temperature')
        threshold = temp_threshold
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

