import requests,os
from datetime import datetime, timedelta
from pymongo import MongoClient, UpdateOne



def lambda_handler(event, context):
    # The URL from which to fetch the timeseries data

    get_weather(os.environ.get("ATLAS_URI"))

def get_weather(host):
    client = MongoClient(host=host)
    db = client['padelTimes']
    clubs_collection = db['clubs']
    
    # Get all clubs with their coordinates
    clubs = list(clubs_collection.find({}))
    
    for club in clubs:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
        }
        
        lat = club.get('latitude')
        lon = club.get('longitude')
        if not lat or not lon:
            print(f"Missing coordinates for club {club['name']}")
            continue
            
        url = f'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat={lat}&lon={lon}'
        response = requests.get(url, headers=headers)
        data = response.json()
        
        insert_weather(data, host, club['name'])

def insert_weather(data, host, club_name):
    client = MongoClient(host=host)
    db = client['padelTimes']
    times_collection = db['times']
    timeseries = data['properties']['timeseries']
    
    requests = []
    
    for entry in timeseries:
        next_hour = entry['data'].get('next_1_hours', {}) or entry['data'].get('next_6_hours', {})
        
        if next_hour:
            precipitation_probability = next_hour.get('details', {}).get('probability_of_precipitation', 0)
            symbol_code = next_hour.get('summary', {}).get('symbol_code',"null")
            wind_speed = entry['data']['instant']['details'].get('wind_speed', 0)        
            dt = datetime.strptime(entry["time"], "%Y-%m-%dT%H:%M:%SZ")
            air_temperature = entry['data']['instant']['details'].get('air_temperature', 0)
            dt_utc_plus_2 = dt + timedelta(hours=2)

            date_string = dt_utc_plus_2.strftime("%Y-%m-%d")
            time_string = dt_utc_plus_2.strftime("%H:%M:%S")

            # Handle interpolation for 6-hour forecasts
            interPolateTime = ['02:00:00','08:00:00','14:00:00','20:00:00']
            if time_string in interPolateTime and not entry['data'].get('next_1_hours', {}).get('details', {}):
                index = timeseries.index(entry)
                next_entry = timeseries[index+1]
                for i in range(1,6):
                    new_dt = dt + timedelta(hours=i+2)
                    new_date_string = new_dt.strftime("%Y-%m-%d")
                    new_time_string = new_dt.strftime("%H:%M:%S")
                    
                    filter = {
                        'date': new_date_string,
                        'time': new_time_string
                    }
                    
                    currentWindSpeed = wind_speed
                    nextWindSpeed = next_entry['data']['instant']['details'].get('wind_speed', 0)
                    new_wind_speed = currentWindSpeed + ((nextWindSpeed - currentWindSpeed) * (i / 4))
                    new_air_temperature = air_temperature + ((next_entry['data']['instant']['details'].get('air_temperature', 0) - air_temperature) * (i / 4))
                    new_precipitation_probability = precipitation_probability + ((next_entry['data']['instant']['details'].get('precipitation_probability', 0) - precipitation_probability) * (i / 4))
                    if new_precipitation_probability < 0:
                        new_precipitation_probability = 0

                    new_symbol_code = entry['data'].get('next_6_hours', {}).get('summary', {}).get('symbol_code')

                    update_object = {
                        '$set': {
                            f'clubs.{club_name}.weather': {
                                'wind_speed': round(new_wind_speed, 1),
                                'precipitation_probability': round(new_precipitation_probability,1),
                                'air_temperature': round(new_air_temperature,1),
                                'symbol_code': new_symbol_code
                            }
                        }
                    }
                    requests.append(UpdateOne(filter, update_object, upsert=True))

            filter = {
                'date': date_string,
                'time': time_string
            }
            
            update_object = {
                '$set': {
                    f'clubs.{club_name}.weather': {
                        'wind_speed': wind_speed,
                        'precipitation_probability': precipitation_probability,
                        'air_temperature': air_temperature,
                        'symbol_code': symbol_code
                    }
                }
            }
            
            requests.append(UpdateOne(filter, update_object, upsert=True))

    result = times_collection.bulk_write(requests)