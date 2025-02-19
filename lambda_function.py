import json

def lambda_handler(event, context):
    # Get all clubs first
    clubs = get_clubs()
    
    # Get court availability for each club
    documents = []
    for time_slot in get_time_slots():
        for club in clubs:
            # Get the existing document from MongoDB for this time slot
            existing_doc = get_existing_document(time_slot['date'], time_slot['time'])
            
            # Create base document
            doc = {
                'time': time_slot['time'],
                'date': time_slot['date'],
                'club_name': club['name'],
                'total_courts': club['total_courts'],
                'air_temperature': None,
                'wind_speed': None,
                'precipitation_probability': None,
                'symbol_code': None
            }
            
            # If we have an existing document, get the weather data from it
            if existing_doc and 'clubs' in existing_doc:
                club_data = existing_doc['clubs'].get(club['name'], {})
                if 'weather' in club_data:
                    weather = club_data['weather']
                    doc.update({
                        'air_temperature': weather.get('air_temperature'),
                        'wind_speed': weather.get('wind_speed'),
                        'precipitation_probability': weather.get('precipitation_probability'),
                        'symbol_code': weather.get('symbol_code')
                    })
            
            # Get court availability
            courts = get_courts(club['url'], time_slot['date'], time_slot['time'])
            if courts is not None:
                # Update document with court data while preserving weather data
                doc.update({
                    'available_courts': courts['available'],
                    'total_available_slots': courts['total_available'],
                    'total_clubs': 1  # This will be updated later
                })
                documents.append(doc)
    
    # Group documents by time slot and update total_clubs
    grouped_docs = {}
    for doc in documents:
        key = f"{doc['date']}T{doc['time']}"
        if key not in grouped_docs:
            grouped_docs[key] = []
        grouped_docs[key].append(doc)
    
    # Update total_clubs for each document
    final_documents = []
    for docs in grouped_docs.values():
        total_clubs = len(docs)
        for doc in docs:
            doc['total_clubs'] = total_clubs
            final_documents.append(doc)
    
    return {
        'statusCode': 200,
        'body': json.dumps(final_documents)
    }

def get_existing_document(date, time):
    # Implement MongoDB query to get existing document
    # This should return the document with the nested weather data
    try:
        # Use your MongoDB client to query the database
        query = {
            'date': date,
            'time': time
        }
        return db.collection.find_one(query)
    except Exception as e:
        print(f"Error getting existing document: {e}")
        return None 