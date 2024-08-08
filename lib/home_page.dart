import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/model/location.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter_application_1/services/notifications_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'custom_app_bar.dart';
import 'document_widget.dart';
import 'main_list_view.dart';
import 'recommended_lv_holder.dart';

class HomePage extends StatefulWidget {

  HomePage();

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {


  double windSpeedThreshold = 50.0;
  double precipitationProbabilityThreshold = 100.0;
  bool showUnavailableSlots = true;
  List<Location> locations = [];
  List<Document> documents = [];
  bool showSliders = false; // Set this based on your logic
  late SharedPreferences sharedPreferences; // Declare prefs as late

  @override
  void initState() {
    super.initState();
     SharedPreferences.getInstance().then((prefs) {
    setState(() => sharedPreferences = prefs);
      windSpeedThreshold = sharedPreferences.getDouble('windSpeedThreshold') ?? 50.0;
     precipitationProbabilityThreshold =
        sharedPreferences.getDouble('precipitationProbabilityThreshold') ?? 100.0;
     showUnavailableSlots =
        sharedPreferences.getBool('showUnavailableSlots') ?? true;
  });
    

    
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
           sharedPreferences.setDouble('windSpeedThreshold', windSpeedThreshold);
      sharedPreferences.setDouble('precipitationProbabilityThreshold', precipitationProbabilityThreshold);
      sharedPreferences.setBool('showUnavailableSlots', showUnavailableSlots);
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
      barrierDismissible: false,
      context: context,
      builder: (BuildContext buildcontext) {
        return StatefulBuilder(
          builder: (buildcontext, state) => AlertDialog(
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
    primary: Color(0xFFFF7F07),
    primaryContainer: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFBBBBBB),
    onSecondary: Color(0xFFEAEAEA),
    tertiary: Color(0xFFFF7F07),
    error: Color(0xFFF32424),
    onError: Color.fromARGB(255, 255, 255, 255),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF505050),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
  );
  
}

  return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),

    
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FirebaseUILocalizations.delegate,

    ],
    supportedLocales: [
      Locale('en', 'US'),
    ],
    title: 'PADELTID',
       theme: ThemeData.light().copyWith(
        colorScheme: darkThemeColors(context),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle( 
        // Status bar color
        statusBarColor: darkThemeColors(context).primaryContainer,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: darkThemeColors(context).tertiary,
          inactiveTrackColor: darkThemeColors(context).onPrimary,
          thumbColor: darkThemeColors(context).tertiary,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
          overlayColor: darkThemeColors(context).onPrimary,
          
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: darkThemeColors(context).onSurface, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w600),
        )
      ),
      
    home: Scaffold(
      
      floatingActionButton: FloatingActionButton(
                        backgroundColor: darkThemeColors(context).onPrimary,
                        foregroundColor: darkThemeColors(context).primary,
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
                  return Center(
                    child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(color: Colors.transparent,),),
                  );
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
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,),
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

            return MainListView(groupedDocuments: groupedDocuments, weekdayName: weekdayName);
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


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}