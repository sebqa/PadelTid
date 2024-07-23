import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/recommended_documents_lv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'document_widget.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  HomePage({required this.prefs});

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
  Color sliderColor = Color(0xFFf9aa08);

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
      floatingActionButton: FloatingActionButton(
                        child: const Icon(Icons.tune),
                        onPressed: showSettingsDialog,

  ),
      
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        slivers: [
                    const SliverAppBar(
            title:  Center(
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
            ),

          
          SliverToBoxAdapter(
            child: Column(
              children: [
                Text('Recommended Timeslots'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100, // Set the height of the horizontal ListView
                    child: documents != null
                        ? RecommendedDocumentsListView(
                            recommendedDocuments: documents,
                          )
                        : CircularProgressIndicator(
                            color: sliderColor,
                          ),
                  ),
                ),

              ],
            ),
            
          ),
          SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      return FutureBuilder<List<Document>>(
        future: fetchDocuments(windSpeedThreshold, precipitationProbabilityThreshold, showUnavailableSlots),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
final Map<String, List<Document>> groupedDocuments = {};
                        for (var document in snapshot.data!) {
                          groupedDocuments.putIfAbsent(document.date, () => [])
                              .add(document);
                        }
                        final weekdayName = [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ];

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
                              child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: groupedDocuments.length,
              itemBuilder: (context, index) {
                final date = groupedDocuments.keys.toList()[index];
                final documentsForDate = groupedDocuments[date]!;
                final parsedDate = DateTime.parse(date);

                          documentsForDate.sort((a, b) => a.time.compareTo(b.time));
                          
                          final formattedDate = '${weekdayName[parsedDate
                              .weekday - 1]}, '
                              '${parsedDate.day}/${parsedDate
                              .month}/${parsedDate.year}';
                return ExpansionTile(
                  subtitle: Text('${documentsForDate.length} timeslots'),
                                title: Row(
                                  children: [
                                    Icon(Icons.calendar_today),
                                    Text(' $formattedDate'),
                                  ],
                                ),
                  children: documentsForDate
                      .map((document) => DocumentWidget(document: document))
                      .toList(),
                );
              },
            ),
                          ),
                        ),
            );
          } else {
            return Center(
              child: Text('No data'),
            );
          }
        },
      );
    },
    childCount: 1, // Change this value if you want to show multiple items in the SliverList
  ),
),
        ],
      ),
    ),
  );
}
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 0; // Minimum height of the header

  @override
  double get maxExtent => 50; // Maximum height of the header

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return false;
  }
}