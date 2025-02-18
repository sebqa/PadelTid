import requests,os
from datetime import datetime, timedelta
from pymongo import MongoClient, UpdateOne



def lambda_handler(event, context):
    # The URL from which to fetch the timeseries data

    get_weather(os.environ.get("ATLAS_URI"))

def get_weather(host):
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'}

    lat = "55.697596"
    lon = "11.68873"
    url = f'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat={lat}&lon={lon}'

    # Make a GET request to the API
    response = requests.get(url,headers=headers)
    data = response.json()
    # Generate and print the HTML table
    weather_inserted = insert_weather(data, host)

# Function to generate HTML table
def insert_weather(data, host):
    client = MongoClient(host=host)

    # Get the 'padelTimes' database, create it if it doesn't exist
    db = client['padelTimes']
    # Get the 'times' collection
    times_collection = db['times']
    timeseries = data['properties']['timeseries']
    
    # Define thresholds for rain and wind sensitivity
    rain_threshold = 15  # in percentage
    wind_threshold = 5   # in m/s
    
    # Initialize the bulk write operations
    requests = []
    
    # Add the rows
    for entry in timeseries:
        # Check if 'next_1_hours' details are available
        next_hour = entry['data'].get('next_1_hours', {}) or entry['data'].get('next_6_hours', {})
        
        # Evaluate suitability for outdoor activities if 'next_1_hours' details are available
        if next_hour:
            precipitation_probability = next_hour.get('details', {}).get('probability_of_precipitation', 0)
            symbol_code = next_hour.get('summary', {}).get('symbol_code',"null")
            wind_speed = entry['data']['instant']['details'].get('wind_speed', 0)        
            # Convert the timestamp string to a datetime object
            dt = datetime.strptime(entry["time"], "%Y-%m-%dT%H:%M:%SZ")
            air_temperature = entry['data']['instant']['details'].get('air_temperature', 0)
            dt_utc_plus_2 = dt + timedelta(hours=2)

            # Convert the date and time parts to strings
            date_string = dt_utc_plus_2.strftime("%Y-%m-%d")
            time_string = dt_utc_plus_2.strftime("%H:%M:%S")

            #check if time is 02, 08, 14 or 20
            interPolateTime = ['02:00:00','08:00:00','14:00:00','20:00:00']

            if time_string in interPolateTime and not entry['data'].get('next_1_hours', {}).get('details', {}) :
                #print("current",date_string,time_string)
                #find next entry in timeseries
                index = timeseries.index(entry)
                next_entry = timeseries[index+1]
                #create new objects for every hour in between
                for i in range(1,6):
                    new_dt = dt + timedelta(hours=i+2)
                    new_date_string = new_dt.strftime("%Y-%m-%d")
                    new_time_string = new_dt.strftime("%H:%M:%S")
                    #print("new",new_date_string, new_time_string)
                    filter = {
                        'date': new_date_string,
                        'time': new_time_string
                    }
                    currentWindSpeed = wind_speed
                    nextWindSpeed = next_entry['data']['instant']['details'].get('wind_speed', 0)
                    # Create the new values for the document by interpolating between the current and next entry, relative to the time distance. e.g. if the current entry at 08:00:00 has wind speed of 10 and the next entry at 14:00:00 has a wind speed of 4, then the entry with the time of 09:00:00 should have a wind speed of 9
                    new_wind_speed = currentWindSpeed + ((nextWindSpeed - currentWindSpeed) * (i / 4))
                    # do the same for other properties
                    new_air_temperature = air_temperature + ((next_entry['data']['instant']['details'].get('air_temperature', 0) - air_temperature) * (i / 4))
                    new_precipitation_probability = precipitation_probability + ((next_entry['data']['instant']['details'].get('precipitation_probability', 0) - precipitation_probability) * (i / 4))
                    #if new_precipitation_probability is negative, set it to 0
                    if new_precipitation_probability < 0:
                        new_precipitation_probability = 0

                    # print(new_wind_speed)
                    # print(new_air_temperature)
                    # print(new_precipitation_probability)  
                    new_symbol_code = entry['data'].get('next_6_hours', {}).get('summary', {}).get('symbol_code')

                    #print(symbol_code)

                    update_object = {
                        '$set': {
                            'wind_speed': round(new_wind_speed, 1),
                            'precipitation_probability':round(new_precipitation_probability,1),
                            'air_temperature':round(new_air_temperature,1),
                            'symbol_code':new_symbol_code
                        }
                    }
                    requests.append(UpdateOne(filter, update_object, upsert=True))
                    


            
            filter = {
                'date': date_string,
                'time': time_string
            }
            
            # Create the new values for the document
            update_object = {
                '$set': {
                    'wind_speed': wind_speed,
                    'precipitation_probability':precipitation_probability,
                    'air_temperature':air_temperature,
                    'symbol_code':symbol_code
                }
            }
            
            # Add the update operation to the requests list
            requests.append(UpdateOne(filter, update_object, upsert=True))

    # Execute the bulk write operations
    result = times_collection.bulk_write(requests)