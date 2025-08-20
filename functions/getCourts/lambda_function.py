import requests,os
from pymongo import MongoClient
from datetime import datetime, timedelta


def getCourts(date):
    # Check if the date is in the past
    input_date = datetime.strptime(date, "%Y-%m-%d").date()
    current_date = datetime.now().date()
    
    if input_date < current_date:
        print(f"Skipping past date: {date}")
        return

    # Connect to the default host and port
    client = MongoClient(host=os.environ.get("ATLAS_URI"))

    # Get the databases
    db = client['padelTimes']
    times_collection = db['times']
    clubs_collection = db['clubs']
    

    # Your HTML content
    request = requests.get("https://holbaekpadel.dk/web/api/group/2431/v2/bookings/overview?date="+date+"&type=weekly")

    sessions = request.json()
    booked_sessions = sessions["booked_sessions"]

    # The possible "from" values to check
    possible_from_values = [
        "06:00:00", "07:00:00", "08:00:00", "09:00:00",
        "10:00:00", "11:00:00", "12:00:00", "13:00:00",
        "14:00:00", "15:00:00", "16:00:00", "17:00:00",
        "18:00:00", "19:00:00", "20:00:00", "21:00:00",
        "22:00:00"
    ]

    club = clubs_collection.find_one({"name": "Holbæk Padel Klub"})
    # Get the current date and time
    current_datetime = datetime.now()

    # Initialize a dictionary to count occurrences
    date_from_counts = {date: {from_time: 0 for from_time in possible_from_values} for session in booked_sessions for date in [session["date"]]}

    for session in booked_sessions:
        session_date = datetime.strptime(session["date"], "%Y-%m-%d")
        session_time = datetime.strptime(session["from"], "%H:%M:%S").time()
        if session["from"] in possible_from_values:
            if session_date > current_datetime or (session_date.date() == current_datetime.date() and session_time > current_datetime.time()):
                date_from_counts[session["date"]][session["from"]] += 1

    # Get court definitions from club document (fallback to default courts if not specified)
    courts_config = club.get('courts', [
        {"name": "Court 1", "court_type": "outdoor"},
        {"name": "Court 2", "court_type": "outdoor"},
        {"name": "Court 3", "court_type": "outdoor"},
        {"name": "Court 4", "court_type": "outdoor"}
    ])
    total_courts = len(courts_config)

    # Find and list available slots
    has_available_slots = []
    for date, from_counts in date_from_counts.items():
        for from_time, count in from_counts.items():
            available_slots = total_courts - count
            
            # Determine which specific courts are available
            courts_status = []
            for i, court_config in enumerate(courts_config):
                is_available = i < available_slots  # First N courts are available
                courts_status.append({
                    "name": court_config["name"],
                    "court_type": court_config["court_type"],
                    "available": is_available
                })
            
            has_available_slots.append((date, from_time, available_slots, courts_status))

    # Print out the result
    for date, from_time, available_slots, courts_status in sorted(has_available_slots):
        available_courts = [c["name"] for c in courts_status if c["available"]]
        print(f"Date: {date}, From time: {from_time}, Available courts: {available_courts}")

    for date, from_time, available_slots, courts_status in sorted(has_available_slots):
        # Create a filter for the document
        filter = {
            'date': date,
            'time': from_time
        }
        
        # Create the club availability update
        club_availability = {
            'club_id': str(club['_id']),
            'club_name': club['name'],
            'club_url': club['url'],
            'latitude': club['latitude'],
            'longitude': club['longitude'],
            'available_slots': available_slots,
            'total_courts': total_courts,
            # Add individual court objects
            'courts': courts_status
        }

        # Update or insert the document while preserving weather data
        existing_doc = times_collection.find_one(filter)
        if existing_doc:
            # If document exists, preserve weather data if it exists
            existing_club_data = existing_doc.get('clubs', {}).get(club['name'], {})
            if 'weather' in existing_club_data:
                club_availability['weather'] = existing_club_data['weather']
            
            # Update only the availability data while preserving other fields
            times_collection.update_one(
                filter,
                {
                    '$set': {
                        f'clubs.{club["name"]}': club_availability
                    }
                }
            )
        else:
            # If document doesn't exist, create it with this club's availability
            times_collection.insert_one({
                **filter,
                'clubs': {
                    club['name']: club_availability
                }
            })

def lambda_handler(event, context):
    # Get the current date
    current_date = datetime.now().strftime("%Y-%m-%d")
    getCourts(current_date)

    # Get the date for one week from now
    date_one_week_later = (datetime.now() + timedelta(weeks=1)).strftime("%Y-%m-%d")
    getCourts(date_one_week_later)

    # Get the date for two weeks from now
    date_two_weeks_later = (datetime.now() + timedelta(weeks=2)).strftime("%Y-%m-%d")
    getCourts(date_two_weeks_later)
