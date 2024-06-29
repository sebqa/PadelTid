import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class Document {
  final double airTemperature;
  final int availableSlots;
  final String date;
  final double precipitationProbability;
  final String time;
  final double windSpeed;

  Document({
    required this.airTemperature,
    required this.availableSlots,
    required this.date,
    required this.precipitationProbability,
    required this.time,
    required this.windSpeed,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      airTemperature: json['air_temperature'],
      availableSlots: json['available_slots'],
      date: json['date'],
      precipitationProbability: json['precipitation_probability'],
      time: json['time'],
      windSpeed: json['wind_speed'],
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  double windSpeedThreshold = 4.0;
  double precipitationProbabilityThreshold = 10.0;
  List<Document> documents = [];





  Future<List<Document>> fetchDocuments(double windSpeed, double precipitationProbability) async {
    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid?wind_speed_threshold=${windSpeedThreshold.toString()}&precipitation_probability_threshold=${precipitationProbabilityThreshold.toString()}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents');
    }
  }

  void updateThresholds() async {
    try {
      final fetchedDocuments = await fetchDocuments(windSpeedThreshold, precipitationProbabilityThreshold);
      setState(() {
        documents = fetchedDocuments;
      });
    } catch (e) {
      // Handle the exception
      print('Failed to fetch documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadelTid',
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'PadelTid',
            style: TextStyle(
              fontSize: 24, // Adjust the font size
              fontWeight: FontWeight.bold, // Make it bold
              fontFamily: 'Roboto', // Choose a nice font family
            ),
          ),
          centerTitle: true, // Center the title
          elevation: 0, // Remove the shadow
          backgroundColor: Colors.transparent, // Make the background transparent
        ),
        body: Column(
          children: [
            Column(
              children: [
                Text('Wind Speed: ${windSpeedThreshold.round()} m/s'),
                Slider(
                  value: windSpeedThreshold,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (double value) {
                    setState(() {
                      windSpeedThreshold = value;
                    });
                    updateThresholds();
                  },
                ),
              ],
            ),
            Column(
              children: [
                Text('Precipitation Probability: ${precipitationProbabilityThreshold.round()}%'),
                Slider(
                  value: precipitationProbabilityThreshold,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (double value) {
                    setState(() {
                      precipitationProbabilityThreshold = value;
                    });
                    updateThresholds();
                  },
                ),
              ],
            ),

            Expanded(
              child: FutureBuilder<List<Document>>(
                future: fetchDocuments(windSpeedThreshold, precipitationProbabilityThreshold),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading documents'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No documents available'));
                  } else {

                    // Group documents by date
                    final Map<String, List<Document>> groupedDocuments = {};
                    for (var document in snapshot.data!) {
                      groupedDocuments.putIfAbsent(document.date, () => []).add(document);
                    }

                    // Create a list of widgets for each group
                    final List<Widget> dateWidgets = [];
                    groupedDocuments.forEach((date, documents) {
                      final parsedDate = DateTime.parse(date);

                      documents.sort((a, b) => a.time.compareTo(b.time));
                      final weekdayName = [
                        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                      ];

                      final formattedDate = '${weekdayName[parsedDate.weekday - 1]}, '
                          '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';

                      dateWidgets.add(
                        ExpansionTile(
                          title: Row(
                            children: [
                              Icon(Icons.calendar_today),
                              Text(' $formattedDate (${documents.length})'),
                            ],
                          ),
                          children: documents.map((document) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Row(
                                    children: [
                                      Icon(Icons.schedule),
                                      Text(' ${document.time}'),
                                    ],
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.air),
                                              Text(' ${document.windSpeed} m/s'),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.thermostat_outlined),
                                              Text(' ${document.airTemperature}°C'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.umbrella),
                                              Text(' ${document.precipitationProbability}%'),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today),
                                              Text(' ${document.availableSlots}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(), // Add a separator
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    });


                    return ListView(children: dateWidgets);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
