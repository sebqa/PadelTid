import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/recommended_documents_lv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'custom_app_bar.dart';
import 'document_widget.dart';
import 'recommended_lv_holder.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  HomePage({required this.prefs});

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
 

  double windSpeedThreshold = 50.0;
  double precipitationProbabilityThreshold = 100.0;
  bool showUnavailableSlots = true;
  List<Document> documents = [];
  bool showSliders = false; // Set this based on your logic
  late SharedPreferences prefs; // Declare prefs as late

  @override
  void initState() {
    super.initState();
    prefs = widget.prefs;
    
     windSpeedThreshold = widget.prefs.getDouble('windSpeedThreshold') ?? 50.0;
     precipitationProbabilityThreshold =
        widget.prefs.getDouble('precipitationProbabilityThreshold') ?? 100.0;
     showUnavailableSlots =
        widget.prefs.getBool('showUnavailableSlots') ?? true;
    
  }

  Future<List<Document>> fetchDocuments(double windSpeed,
      double precipitationProbability, bool showUnavailableSlots) async {
    final url = Uri.parse(
        'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid?wind_speed_threshold=$windSpeed&precipitation_probability_threshold=$precipitationProbability&showUnavailableSlots=$showUnavailableSlots');
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
     

      final fetchedDocuments = await fetchDocuments(
          windSpeedThreshold, precipitationProbabilityThreshold, showUnavailableSlots);
           prefs.setDouble('windSpeedThreshold', windSpeedThreshold);
      prefs.setDouble('precipitationProbabilityThreshold', precipitationProbabilityThreshold);
      prefs.setBool('showUnavailableSlots', showUnavailableSlots);
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
      //call updateThresholds() when dialog is closed
      barrierDismissible: false,

      context: context,
      builder: (BuildContext context) {
        
          final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  Color sliderColor = colorScheme.secondary;
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
                child: Text('Apply'),
                onPressed: () {
                  updateThresholds();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Cancel'),
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

ColorScheme darkThemeColors(context) {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFFFFFF),
    onPrimary: Color.fromARGB(255, 74, 73, 73),
    secondary: Color(0xFFBBBBBB),
    onSecondary: Color(0xFFEAEAEA),
    tertiary: Color(0xFFFF7F07),
    error: Color(0xFFF32424),
    onError: Color(0xFFF32424),
    background: Color(0xFF202020),
    onBackground: Color(0xFF505050),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
  );
  
}

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
       theme: ThemeData.light().copyWith(
        colorScheme: darkThemeColors(context),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle( //<-- SEE HERE
        // Status bar color
        statusBarColor: darkThemeColors(context).tertiary,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: darkThemeColors(context).onPrimary, fontSize: 11, fontFamily: 'Roboto', fontWeight: FontWeight.w300),
        )
      ),
      
    home: Scaffold(
      
      floatingActionButton: FloatingActionButton(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFFFF7F07),
                        child: const Icon(Icons.tune),
                        onPressed: showSettingsDialog,

  ),
      
      body: CustomScrollView(
        
        physics: const AlwaysScrollableScrollPhysics(),

        slivers: [
          CustomAppBar(),
          SliverToBoxAdapter(
            
            child: 
            FutureBuilder<List<Document>>(
              future: fetchDocuments(4.0, 10.0, false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return recommended_lv_holder(documents: snapshot.data!);
                }
              },
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0,8.0,8.0,0),
                            child: Container(
                              decoration:  BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                  topRight: Radius.circular(16.0),
                                ),
                                color: Theme.of(context).colorScheme.primary,
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
                return Column(
                  children: [
                    ExpansionTile(
                      shape: Border(),
                      subtitle: Text('${documentsForDate.length} timeslots'),
                      title: Row(
                        children: [
                          Icon(
                            color: Theme.of(context).colorScheme.tertiary,
                            Icons.calendar_today),
                          Text(' $formattedDate'),
                        ],
                      ),
                      children: [
                        ListViewbuilder(documentsForDate: documentsForDate),
                      ],
                    ),
                    Divider(thickness: 0.5,)
                  ],
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

class ListViewbuilder extends StatelessWidget {
  const ListViewbuilder({
    super.key,
    required this.documentsForDate,
  });

  final List<Document> documentsForDate;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
separatorBuilder: (context, index) => Divider(thickness: 0.5),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: documentsForDate.length,
      itemBuilder: (context, index) {
        final document = documentsForDate[index];
        return DocumentWidget(document: document);
      },
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


