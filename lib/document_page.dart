import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'dart:js' as js;
import 'package:http/http.dart' as http;

class DocumentPage extends StatefulWidget {
  final Document document;

  DocumentPage({required this.document});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  final Uri _url = Uri.parse('https://holbaekpadel.dk/da/new/booking');
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    final response = await http.get(Uri.parse(
        'https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=55.697596&lon=11.68873'));
    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.document.date),
      ),
      body: SafeArea(
        child: WeatherPage(weatherData: weatherData!),
      ),
    );
  }
}

class WeatherPage extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  WeatherPage({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final currentData = weatherData['properties']['timeseries'][0]['data'];
    final nextHourData = weatherData['properties']['timeseries'][1]['data'];
    final twoHoursData = weatherData['properties']['timeseries'][2]['data'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for a city or airport',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // City list
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildCityItem('San Francisco', isSelected: false),
                      _buildCityItem('San Mateo', isSelected: true),
                      _buildCityItem('Tahoe City', isSelected: false),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text('Now', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.wb_sunny, size: 40),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentData['instant']['details']['air_temperature']}° ${currentData['next_1_hours']['summary']['symbol_code']}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'H: ${currentData['next_6_hours']['details']['air_temperature_max']}° - L: ${currentData['next_6_hours']['details']['air_temperature_min']}°',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text('Temperature',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Text(
                  '${currentData['instant']['details']['air_temperature']}°',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text('Now 0%', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 16),
                // Temperature graph would go here
                SizedBox(height: 24),
                Text('Next 2 hours',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                _buildHourlyForecast(nextHourData),
                _buildHourlyForecast(twoHoursData),
                SizedBox(height: 24),
                Text('Wind', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.air, size: 30),
                    SizedBox(width: 16),
                    Text(
                      '${currentData['instant']['details']['wind_speed']} m/s',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(width: 16),
                    Transform.rotate(
                      angle: (currentData['instant']['details']
                                  ['wind_from_direction'] *
                              3.14159 /
                              180) -
                          3.14159 / 2,
                      child: Icon(Icons.arrow_upward, size: 30),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityItem(String cityName, {required bool isSelected}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        cityName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> hourData) {
    return ListTile(
      leading: Icon(Icons.wb_sunny),
      title: Text(
        '${hourData['next_1_hours']['summary']['symbol_code']}, ${hourData['instant']['details']['air_temperature']}°',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
          'Precipitation: ${hourData['next_1_hours']['details']['precipitation_amount']} mm'),
    );
  }
}

class subscribingIcon extends StatefulWidget {
  const subscribingIcon(
      {super.key, required this.document, required this.user});

  final Document document;
  final User user;

  @override
  State<subscribingIcon> createState() => _subscribingIconState();
}

class _subscribingIconState extends State<subscribingIcon> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool subscribing = false;

  @override
  void initState() {
    super.initState();
    subscribing = widget.document.subscribed ?? false;
  }

  Future<String> getFCMToken(userId) async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    final fcmToken = await messaging.getToken(
        vapidKey:
            "BIrzD_lqpWDvg6nMYArPnCbQeg1nqkRT-K4LyCBHahJws-7xceAPI2dDegDA-09TfRt1pIgbtGGETxLas3rAJpw");
    return fcmToken!;
  }

  subscribeToTopic(Document document, Future<String> fcmToken, String subscribe,
      User user) async {
    //make a get request to url
    String token = await fcmToken;
    print(token);
    String? jwt = await user.getIdToken();
    print(jwt);

    String url =
        "https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/subTopic?date=${document.date}&time=${document.time}:00&subscribe=$subscribe&device_token=${token}&userId=${widget.user.uid}";

    final response = await http.get(Uri.parse(url));
    // final response = await http.get(Uri.parse(url),
    // headers: {HttpHeaders.authorizationHeader: 'Bearer $jwt'});

    if (response.statusCode == 200) {
      String subscribed = response.body;
      //create JSON object from response.body
      Map<String, dynamic> jsonData = json.decode(subscribed);
      if (jsonData['subscribe'] == 'true') {
        print('Subscribed to topic ' +
            document.date.replaceAll("-", "") +
            document.time.replaceAll(":", "") +
            '00');
      } else {
        print("Unsubscribed from topic " +
            document.date.replaceAll("-", "") +
            document.time.replaceAll(":", "") +
            '00');
      }
    } else {
      throw Exception('Failed to subscribe to topic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        subscribing ? Icons.star : Icons.star_border,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        setState(() {
          subscribing = !subscribing;
        });

        //with fcm, subscribe to the topic
        final fcmToken = getFCMToken(widget.user.uid);
        //subscribe to the topic
        subscribeToTopic(widget.document, fcmToken,
            subscribing ? 'true' : 'false', widget.user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              subscribing
                  ? 'Subscribed to timeslot'
                  : 'No longer subscribed to timeslot',
            ),
          ),
        );
      },
    );
  }
}
