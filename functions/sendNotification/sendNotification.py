def send_notification(event):
    print(f"Starting send_notification with event: {event}")
    
    date = event['detail']['fullDocument']['date']
    time = event['detail']['fullDocument']['time']
    doc_id = date.replace("-", "") + time.replace(":", "")
    print(f"Processing document ID: {doc_id}")
    
    # Get current and previous states
    current_doc = event['detail']['fullDocument']
    previous_doc = event['detail'].get('fullDocumentBeforeChange', {})
    print(f"Previous doc available: {bool(previous_doc)}")
    
    # Initialize notification data
    title = date.split('-')[2] + "/" + date.split('-')[1] + " " + time[:5]
    
    # Connect to MongoDB
    print("Attempting to connect to MongoDB...")
    try:
        client = MongoClient(os.environ['MONGODB_URI'])
        db = client.padeltid
        users_collection = db.users
        print("Successfully connected to MongoDB")
    except Exception as e:
        print(f"Failed to connect to MongoDB: {str(e)}")
        raise

    # Find all users subscribed to this time slot
    print(f"Searching for users subscribed to {doc_id}")
    users = users_collection.find({
        "subscriptions": {
            "$elemMatch": {
                "id": doc_id
            }
        }
    })
    
    users_list = list(users)  # Convert cursor to list for logging
    print(f"Found {len(users_list)} subscribed users")

    notifications_sent = 0
    
    for user in users_list:
        print(f"\nProcessing user: {user['_id']}")
        
        # Get the user's preferences for this time slot
        subscription = next(
            (sub for sub in user['subscriptions'] if sub['id'] == doc_id), 
            None
        )
        if not subscription or not subscription.get('preferences'):
            print(f"No valid subscription or preferences found for user {user['_id']}")
            continue

        preferences = subscription['preferences']
        print(f"User preferences: {preferences}")
        
        # Get the most recent token
        tokens = user.get('tokens', [])
        if not tokens:
            print(f"No tokens found for user {user['_id']}")
            continue
            
        # Sort tokens by lastUsedAt and get the most recent one
        most_recent_token = max(tokens, key=lambda x: x['lastUsedAt'])
        token = most_recent_token['token']
        print(f"Using token from {most_recent_token['lastUsedAt']}")

        # Check conditions and send appropriate notifications
        for club_id, club_data in current_doc.get('clubs', {}).items():
            print(f"\nChecking club: {club_id}")
            previous_club_data = previous_doc.get('clubs', {}).get(club_id, {})
            
            current_weather = club_data.get('weather', {})
            previous_weather = previous_club_data.get('weather', {})
            
            current_slots = club_data.get('available_slots', 0)
            previous_slots = previous_club_data.get('available_slots', 0)
            
            print(f"Current slots: {current_slots}, Previous slots: {previous_slots}")
            print(f"Current weather: {current_weather.get('symbol_code')}, Previous weather: {previous_weather.get('symbol_code')}")
            
            notification_body = None
            
            # Check weather changes
            if (preferences.get('notifyOnWeatherChange') and 
                previous_weather and 
                current_weather.get('symbol_code') != previous_weather.get('symbol_code')):
                notification_body = f"Weather changed to {current_weather.get('symbol_code')}"
                print("Weather change notification triggered")
            
            # Check availability changes
            elif preferences.get('notifyWhenAvailable') and previous_slots == 0 and current_slots > 0:
                notification_body = "Courts now available"
                print("Courts available notification triggered")
            
            # Check when only one court is left
            elif preferences.get('notifyWhenOneLeft') and previous_slots > 1 and current_slots == 1:
                notification_body = "Only one court left"
                print("One court left notification triggered")
            
            # Check when courts become full
            elif preferences.get('notifyWhenFull') and previous_slots > 0 and current_slots == 0:
                notification_body = "No more available courts"
                print("Courts full notification triggered")
            
            if notification_body:
                print(f"Sending notification to user {user['_id']}: {notification_body}")
                # Send notification to this specific user
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=notification_body
                    ),
                    token=token
                )
                
                try:
                    response = messaging.send(message)
                    print(f'Successfully sent message to user {user["_id"]}: {response}')
                    notifications_sent += 1
                    break  # Break after sending first applicable notification
                except Exception as e:
                    print(f'Failed to send message to user {user["_id"]}: {str(e)}')
                    print(f'Message that failed: {message}')

    client.close()
    print(f"\nNotification process completed. Sent {notifications_sent} notifications")
    return f"Sent {notifications_sent} notifications" 