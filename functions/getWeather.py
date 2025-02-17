import requests
from datetime import datetime, timedelta
from pymongo import MongoClient



def getWeather():
    # The URL from which to fetch the timeseries data
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'}

    url = "https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=55.697596&lon=11.68873"

    # Make a GET request to the API
    response = requests.get(url,headers=headers)
    data = response.json()
    # Generate and print the HTML table
    html_table = generate_html_table(data)
    return html_table


# Function to generate HTML table
def generate_html_table(data):
    client = MongoClient('mongodb://172.17.0.2:27017')

    # Get the 'padelTimes' database, create it if it doesn't exist
    db = client['padelTimes']
    # Get the 'times' collection
    times_collection = db['times']
    timeseries = data['properties']['timeseries']
    
    # Define thresholds for rain and wind sensitivity
    rain_threshold = 15  # in percentage
    wind_threshold = 5   # in m/s
    
    # Start the HTML table
    html_table = '<table border="1">\n'
    
    # Add the headers
    headers = ['time', 'suitability']  # Fixed headers
    html_table += '<tr>' + ''.join(f'<th>{header}</th>' for header in headers) + '</tr>\n'
    
    # Add the rows
    for entry in timeseries:
        # Check if 'next_1_hours' details are available
        next_hour_details = entry['data'].get('next_1_hours', {}).get('details', {}) if entry['data'].get('next_1_hours', {}).get('details', {}) else entry['data'].get('next_6_hours', {}).get('details', {}) 
        
        # Evaluate suitability for outdoor activities if 'next_1_hours' details are available
        if next_hour_details:
            precipitation_probability = next_hour_details.get('probability_of_precipitation', 0)
            wind_speed = entry['data']['instant']['details'].get('wind_speed', 0)        
            # Convert the timestamp string to a datetime object
            dt = datetime.strptime(entry["time"], "%Y-%m-%dT%H:%M:%SZ")
            air_temperature = entry['data']['instant']['details'].get('air_temperature', 0)
            dt_utc_plus_2 = dt + timedelta(hours=2)

            # Convert the date and time parts to strings
            date_string = dt_utc_plus_2.strftime("%Y-%m-%d")
            time_string = dt_utc_plus_2.strftime("%H:%M:%S")

            # Print the results
            print("Date:", date_string)
            print("Time:", time_string)
            print("Wind:", wind_speed)

            filter = {
                'date': date_string,
                'time': time_string
            }
            
            # Create the new values for the document
            new_values = {
                '$set': {
                    'wind_speed': wind_speed,
                    'precipitation_probability':precipitation_probability,
                    'air_temperature':air_temperature
                }
            }
            
            # Update the document with upsert=True to insert if it doesn't exist
            times_collection.update_one(filter, new_values, upsert=True)
getWeather()