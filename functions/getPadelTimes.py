from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Set up MongoDB connection
client = MongoClient('mongodb://172.17.0.2:27017')
db = client['padelTimes']
collection = db['times']

@app.route('/query', methods=['GET'])
def query_times():
    try:
        wind_speed_threshold = float(request.args.get('wind_speed_threshold'))
        precipitation_probability_threshold = float(request.args.get('precipitation_probability_threshold'))
        current_time = datetime.now()  # Get the current date and time
        current_time_str = current_time.strftime('%Y-%m-%d %H:%M:%S')  # Format current time as string

        # Query the collection
        query = {
            'precipitation_probability': {'$lt': precipitation_probability_threshold},
            'wind_speed': {'$lt': wind_speed_threshold},
            'available_slots': {'$gt': 0},
            '$expr': {  # Use $expr to enable comparison of fields
                '$gt': [
                    { '$concat': ['$date', ' ', '$time'] },  # Concatenate date and time fields
                    current_time_str  # Compare with current time string
                ]
            }
        }

        results = list(collection.find(query, {'_id': 0}))

        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True,host="0.0.0.0")
