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
        # Try to get the most accurate forecast available
        next_hour = entry['data'].get('next_1_hours', {})
        if not next_hour:
            next_hour = entry['data'].get('next_6_hours', {})
        if not next_hour:
            next_hour = entry['data'].get('next_12_hours', {})
        
        if next_hour:
            # Get instant weather details
            instant_details = entry['data']['instant']['details']
            wind_speed = instant_details.get('wind_speed', 0)
            air_temperature = instant_details.get('air_temperature', 0)
            
            # Get precipitation probability from the most accurate forecast available
            precipitation_probability = 0
            if entry['data'].get('next_1_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                precipitation_probability = entry['data']['next_1_hours']['details']['probability_of_precipitation']
            elif entry['data'].get('next_6_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                precipitation_probability = entry['data']['next_6_hours']['details']['probability_of_precipitation']
            elif entry['data'].get('next_12_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                precipitation_probability = entry['data']['next_12_hours']['details']['probability_of_precipitation']
            
            # Get symbol code from the most accurate forecast available
            symbol_code = None
            if entry['data'].get('next_1_hours', {}).get('summary', {}).get('symbol_code'):
                symbol_code = entry['data']['next_1_hours']['summary']['symbol_code']
            elif entry['data'].get('next_6_hours', {}).get('summary', {}).get('symbol_code'):
                symbol_code = entry['data']['next_6_hours']['summary']['symbol_code']
            elif entry['data'].get('next_12_hours', {}).get('summary', {}).get('symbol_code'):
                symbol_code = entry['data']['next_12_hours']['summary']['symbol_code']
            else:
                symbol_code = "null"
                
            dt = datetime.strptime(entry["time"], "%Y-%m-%dT%H:%M:%SZ")
            dt_utc_plus_2 = dt + timedelta(hours=2)

            date_string = dt_utc_plus_2.strftime("%Y-%m-%d")
            time_string = dt_utc_plus_2.strftime("%H:%M:%S")

            # Handle interpolation for 6-hour forecasts
            interPolateTime = ['02:00:00','08:00:00','14:00:00','20:00:00']
            if time_string in interPolateTime and not entry['data'].get('next_1_hours', {}).get('details', {}):
                index = timeseries.index(entry)
                next_entry = timeseries[index+1]
                
                # Get next entry's instant details
                next_instant_details = next_entry['data']['instant']['details']
                next_wind_speed = next_instant_details.get('wind_speed', 0)
                next_air_temperature = next_instant_details.get('air_temperature', 0)
                
                for i in range(1,6):
                    new_dt = dt + timedelta(hours=i+2)
                    new_date_string = new_dt.strftime("%Y-%m-%d")
                    new_time_string = new_dt.strftime("%H:%M:%S")
                    
                    filter = {
                        'date': new_date_string,
                        'time': new_time_string
                    }
                    
                    # Linear interpolation of instant weather values
                    new_wind_speed = wind_speed + ((next_wind_speed - wind_speed) * (i / 4))
                    new_air_temperature = air_temperature + ((next_air_temperature - air_temperature) * (i / 4))
                    
                    # Get next entry's precipitation probability
                    next_precipitation_probability = 0
                    if next_entry['data'].get('next_1_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                        next_precipitation_probability = next_entry['data']['next_1_hours']['details']['probability_of_precipitation']
                    elif next_entry['data'].get('next_6_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                        next_precipitation_probability = next_entry['data']['next_6_hours']['details']['probability_of_precipitation']
                    elif next_entry['data'].get('next_12_hours', {}).get('details', {}).get('probability_of_precipitation') is not None:
                        next_precipitation_probability = next_entry['data']['next_12_hours']['details']['probability_of_precipitation']
                    
                    # Linear interpolation of precipitation probability
                    new_precipitation_probability = precipitation_probability + ((next_precipitation_probability - precipitation_probability) * (i / 4))
                    if new_precipitation_probability < 0:
                        new_precipitation_probability = 0

                    # Use the more accurate symbol code from the appropriate forecast period
                    new_symbol_code = entry['data'].get('next_6_hours', {}).get('summary', {}).get('symbol_code')
                    if not new_symbol_code:
                        new_symbol_code = entry['data'].get('next_12_hours', {}).get('summary', {}).get('symbol_code', "null")
                    
                    # Create update object that preserves existing data
                    update_object = {
                        '$set': {
                            f'clubs.{club_name}.weather': {
                                'wind_speed': round(new_wind_speed, 1),
                                'precipitation_probability': round(new_precipitation_probability,1),
                                'air_temperature': round(new_air_temperature,1),
                                'symbol_code': new_symbol_code,
                                'last_updated': datetime.utcnow().isoformat()
                            }
                        }
                    }
                    requests.append(UpdateOne(filter, update_object, upsert=True))

            filter = {
                'date': date_string,
                'time': time_string
            }
            
            # Create update object that preserves existing data
            update_object = {
                '$set': {
                    f'clubs.{club_name}.weather': {
                        'wind_speed': round(wind_speed, 1),
                        'precipitation_probability': round(precipitation_probability, 1),
                        'air_temperature': round(air_temperature, 1),
                        'symbol_code': symbol_code,
                        'last_updated': datetime.utcnow().isoformat()
                    }
                }
            }
            
            requests.append(UpdateOne(filter, update_object, upsert=True))

    if requests:
        result = times_collection.bulk_write(requests)
        print(f"Updated weather data for {club_name}: {result.modified_count} documents modified")