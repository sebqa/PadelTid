import requests
from datetime import datetime, timedelta
from pymongo import UpdateOne
from config.database import get_db_padel_times
import logging

logger = logging.getLogger(__name__)

class WeatherService:
    def __init__(self):
        self.db = get_db_padel_times
    
    async def update_all_weather(self):
        """Update weather data for all clubs"""
        try:
            clubs_collection = self.db()['clubs']
            clubs = list(clubs_collection.find({}))
            
            results = []
            for club in clubs:
                try:
                    result = await self.update_club_weather(club)
                    results.append({"club": club.get('name', 'unknown'), "status": "success", "result": result})
                except Exception as e:
                    logger.error(f"Error updating weather for club {club.get('name', 'unknown')}: {str(e)}")
                    results.append({"club": club.get('name', 'unknown'), "status": "error", "error": str(e)})
            
            return results
            
        except Exception as e:
            logger.error(f"Error in update_all_weather: {str(e)}")
            raise e
    
    async def update_club_weather(self, club):
        """Update weather data for a specific club"""
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
        }
        
        lat = club.get('latitude')
        lon = club.get('longitude')
        if not lat or not lon:
            logger.warning(f"Missing coordinates for club {club.get('name', 'unknown')}")
            return {"error": "Missing coordinates"}
            
        url = f'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat={lat}&lon={lon}'
        response = requests.get(url, headers=headers)
        data = response.json()
        
        return await self.insert_weather_data(data, club['name'])
    
    async def insert_weather_data(self, data, club_name):
        """Insert weather data into database"""
        times_collection = self.db()['times']
        timeseries = data['properties']['timeseries']
        
        requests_list = []
        
        for entry in timeseries:
            # Get forecast data
            next_hour = entry['data'].get('next_1_hours', {})
            if not next_hour:
                next_hour = entry['data'].get('next_6_hours', {})
            if not next_hour:
                next_hour = entry['data'].get('next_12_hours', {})
            
            if next_hour:
                instant_details = entry['data']['instant']['details']
                wind_speed = instant_details.get('wind_speed', 0)
                air_temperature = instant_details.get('air_temperature', 0)
                
                # Get precipitation probability
                precipitation_probability = 0
                for period in ['next_1_hours', 'next_6_hours', 'next_12_hours']:
                    if entry['data'].get(period, {}).get('details', {}).get('probability_of_precipitation') is not None:
                        precipitation_probability = entry['data'][period]['details']['probability_of_precipitation']
                        break
                
                # Get symbol code
                symbol_code = "null"
                for period in ['next_1_hours', 'next_6_hours', 'next_12_hours']:
                    if entry['data'].get(period, {}).get('summary', {}).get('symbol_code'):
                        symbol_code = entry['data'][period]['summary']['symbol_code']
                        break
                        
                dt = datetime.strptime(entry["time"], "%Y-%m-%dT%H:%M:%SZ")
                dt_utc_plus_2 = dt + timedelta(hours=2)

                date_string = dt_utc_plus_2.strftime("%Y-%m-%d")
                time_string = dt_utc_plus_2.strftime("%H:%M:%S")

                filter_doc = {
                    'date': date_string,
                    'time': time_string
                }
                
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
                
                requests_list.append(UpdateOne(filter_doc, update_object, upsert=True))

        if requests_list:
            result = times_collection.bulk_write(requests_list)
            logger.info(f"Updated weather data for {club_name}: {result.modified_count} documents modified")
            return {"modified_count": result.modified_count, "upserted_count": result.upserted_count}
        
        return {"modified_count": 0, "upserted_count": 0}
    
    async def get_club_weather(self, club_name: str):
        """Get current weather data for a specific club"""
        try:
            times_collection = self.db()['times']
            current_time = datetime.now()
            current_date = current_time.strftime('%Y-%m-%d')
            
            # Find recent weather data for the club
            query = {
                'date': {'$gte': current_date},
                f'clubs.{club_name}.weather': {'$exists': True}
            }
            
            projection = {
                '_id': 0,
                'date': 1,
                'time': 1,
                f'clubs.{club_name}.weather': 1
            }
            
            results = list(times_collection.find(query, projection).sort([("date", 1), ("time", 1)]).limit(10))
            
            return {
                "club": club_name,
                "weather_data": results
            }
            
        except Exception as e:
            logger.error(f"Error in get_club_weather: {str(e)}")
            raise e 