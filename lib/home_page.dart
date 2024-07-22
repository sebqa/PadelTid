import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/recommended_documents_lv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  HomePage({required this.prefs});

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
  Color sliderColor = Color(0xFFf9aa08);
  Color primaryColor = Color(0xFFCDDC39); // Remove the FF for opacity as primarySwatch handles it

  double windSpeedThreshold = 4.0;
  double precipitationProbabilityThreshold = 10.0;
  bool showUnavailableSlots = false;
  List<Document> documents = [];
  bool showSliders = false; // Set this based on your logic
  late SharedPreferences prefs; // Declare prefs as late

  @override
  void initState() {
    super.initState();
    prefs = widget.prefs;
    fetchDocuments(windSpeedThreshold, precipitationProbabilityThreshold, showUnavailableSlots).then((value) {
      setState(() {
        documents = value;
      });
    });
  }

  Future<List<Document>> fetchDocuments(double windSpeed,
      double precipitationProbability, bool showUnavailableSlots) async {
    final windSpeedThreshold = widget.prefs.getDouble('windSpeedThreshold') ?? 4.0;
    final precipitationProbabilityThreshold =
        widget.prefs.getDouble('precipitationProbabilityThreshold') ?? 10.0;
    final showUnavailableSlots =
        widget.prefs.getBool('showUnavailableSlots') ?? false;


    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid?wind_speed_threshold=$windSpeedThreshold&precipitation_probability_threshold=$precipitationProbabilityThreshold&showUnavailableSlots=$showUnavailableSlots');
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
      prefs.setDouble('windSpeedThreshold', windSpeedThreshold);
      prefs.setDouble('precipitationProbabilityThreshold', precipitationProbabilityThreshold);
      prefs.setBool('showUnavailableSlots', showUnavailableSlots);

      final fetchedDocuments = await fetchDocuments(
          windSpeedThreshold, precipitationProbabilityThreshold, showUnavailableSlots);
      setState(() {
        documents = fetchedDocuments;
      });
    } catch (e) {
      // Handle the exception
      print('Failed to fetch documents: $e');
    }
  }
  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, state) => AlertDialog(
            title: Text('Adjust Thresholds'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    children: [
                      Text('Wind Speed: ${windSpeedThreshold.round()} m/s'),
                      Slider(
                        value: windSpeedThreshold,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        activeColor: sliderColor,
                        onChanged: (double value) {
                          state(() {
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
                        activeColor: sliderColor,
                        onChanged: (double value) {
                          state(() {
                            precipitationProbabilityThreshold = value;
                          });
                          updateThresholds();
                        },
                      ),

                    ],
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: showUnavailableSlots,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            state(() {
                              showUnavailableSlots = newValue;
                              updateThresholds();
                            });
                          }
                        },
                      ),
                      Text('Show unavailable timeslots'),
                    ],
                  )

                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
return MaterialApp(
        theme: ThemeData(
      colorScheme: ColorScheme.light().copyWith(primary: primaryColor),

                  // ... other theme properties
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        supportedLocales: [
          Locale('en', 'US'),
        ],
        title: 'PADELTID',
        home: Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0.0,
            title: Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Baseline(
          baselineType: TextBaseline.alphabetic,
          baseline: 28.0, // Adjust this value as needed
          child: Text(
            'PADEL',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        Baseline(
          baselineType: TextBaseline.alphabetic,
          baseline: 28.0, // Same baseline value
          child: Text(
            'TID',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    ),
  ),
            elevation: 0,
            backgroundColor: Colors.white,

            actions: [
              IconButton(
                color: Colors.black,
                icon: const Icon(Icons.tune),
                tooltip: 'Show filter',
                onPressed: showSettingsDialog
              ),
            ],// Make the background transparent
          ),
          body: Column(
              children: [
                Text('Recommended Timeslots'),
                 SizedBox(
          height: 100, // Set the height of the horizontal ListView
          child: RecommendedDocumentsListView(recommendedDocuments: documents)
        ),

                Expanded(

                  child: FutureBuilder<List<Document>>(
                    future: fetchDocuments(
                        windSpeedThreshold, precipitationProbabilityThreshold, showUnavailableSlots),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(
                          color: sliderColor,
                        ));
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading documents'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No documents available'));
                      } else {
                        // Group documents by date and sort by date

                        final Map<String, List<Document>> groupedDocuments = {};
                        for (var document in snapshot.data!) {
                          groupedDocuments.putIfAbsent(document.date, () => [])
                              .add(document);
                        }
                        

    
                        // Create a list of widgets for each group
                        final List<Widget> dateWidgets = [];
                        groupedDocuments.forEach((date, documents) {
                          final parsedDate = DateTime.parse(date);

                          documents.sort((a, b) => a.time.compareTo(b.time));
                          final weekdayName = [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ];

                          final formattedDate = '${weekdayName[parsedDate
                              .weekday - 1]}, '
                              '${parsedDate.day}/${parsedDate
                              .month}/${parsedDate.year}';

                          dateWidgets.add(
                            Theme(
                              data: ThemeData().copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                subtitle: Text('${documents.length} timeslots'),
                                title: Row(
                                  children: [
                                    Icon(Icons.calendar_today),
                                    Text(' $formattedDate'),
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
                                          mainAxisAlignment: MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.air),
                                                    Text(' ${document
                                                        .windSpeed} m/s'),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons
                                                        .thermostat_outlined),
                                                    Text(' ${document
                                                        .airTemperature}°C'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.umbrella),
                                                    Text(' ${document
                                                        .precipitationProbability}%'),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today),
                                                    Text(' ${document
                                                        .availableSlots ?? "0"}'),
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
                            ),
                          );
                        });

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set your desired background color
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0,8.0,8.0,0),
                            child: Container(
                              decoration:  BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                  topRight: Radius.circular(16.0),
                                ),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25), // Shadow color with opacity
                                    spreadRadius: 1, // Spread radius
                                    blurRadius: 4, // Blur radius
                                    offset: Offset(0, -1), // Offset (x, y), negative y to have the shadow on top
                                  ),
                                ],// Set your desired background color
                              ),
                              child: ListView.separated(
                                itemCount: dateWidgets.length,
                                separatorBuilder: (BuildContext context, int index) {
                                  return Divider(
                                    color: Colors.grey, // Customize the color of the divider
                                    thickness: 1.0, // Set the thickness of the divider
                                  );
                                },
                                itemBuilder: (BuildContext context, int index) {
                                  return dateWidgets[index];
                                },
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

              ]),
        )
    );
  }
}