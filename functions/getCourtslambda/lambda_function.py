import requests,os
from pymongo import MongoClient
from datetime import datetime, timedelta


def getCourts(date):
    # Connect to the default host and port
    client = MongoClient(host=os.environ.get("ATLAS_URI"))

    # Get the 'padelTimes' database, create it if it doesn't exist
    db = client['padelTimes']

    # Get the 'times' collection
    times_collection = db['times']
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

    # Get the current date and time
    current_datetime = datetime.now()

    # Initialize a dictionary to count occurrences of each date for each "from" value
    date_from_counts = {date: {from_time: 0 for from_time in possible_from_values} for session in booked_sessions for date in [session["date"]]}

    for session in booked_sessions:
        session_date = datetime.strptime(session["date"], "%Y-%m-%d")
        session_time = datetime.strptime(session["from"], "%H:%M:%S").time()
        if session["from"] in possible_from_values:
            if session_date > current_datetime or (session_date.date() == current_datetime.date() and session_time > current_datetime.time()):
                date_from_counts[session["date"]][session["from"]] += 1

    # Find and list available slots for all times
    has_available_slots = []
    total_courts = 8  # Total number of courts available at all hours

    for date, from_counts in date_from_counts.items():
        for from_time, count in from_counts.items():
            available_slots = total_courts - count
            has_available_slots.append((date, from_time, available_slots))

    # Print out the result
    for date, from_time, available_slots in sorted(has_available_slots):
        print(f"Date: {date}, From time: {from_time}, Available slots: {available_slots}")

    for date, from_time, available_slots in sorted(has_available_slots):
        # Create a filter for the document based on date and time
        filter = {
            'date': date,
            'time': from_time
        }
        
        # Create the new values for the document
        new_values = {
            '$set': {
                'available_slots': available_slots
            }
        }
        
        # Update the document with upsert=True to insert if it doesn't exist
        times_collection.update_one(filter, new_values, upsert=True)

def lambda_handler(event, context):
    # Get the current date
    current_date = datetime.now().strftime("%Y-%m-%d")
    getCourts(current_date)

    # Get the date for one week from now
    date_one_week_later = (datetime.now() + timedelta(weeks=1)).strftime("%Y-%m-%d")
    getCourts(date_one_week_later)
