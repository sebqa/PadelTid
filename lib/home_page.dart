import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/consent_snackbar.dart';
import 'package:flutter_application_1/document_service.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login_page.dart';
import 'document_widget.dart';
import 'main_list_view.dart';
import 'recommended_lv_holder.dart';
import 'package:flutter/services.dart';
import 'onboarding_screen.dart';
import 'location_selector.dart';

class Location {
  final String name;
  final String location;
  final String imageUrl;

  Location(
      {required this.name, required this.location, required this.imageUrl});
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double windSpeedThreshold = 50.0;
  double precipitationProbabilityThreshold = 100.0;
  bool showUnavailableSlots = true;
  late SharedPreferences sharedPreferences;
  late Future<List<Document>> futureDocuments;
  late Future<List<Document>>? recommendedDocuments;
  final DocumentService documentService = DocumentService();
  bool consentShown = false;
  bool _showOnboarding = false;
  List<String> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _initializePreferences();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    _selectedLocations = prefs.getStringList('selected_locations') ?? [];
    
    setState(() {
      _showOnboarding = !hasSeenOnboarding;
      if (!_showOnboarding) {
        windSpeedThreshold = prefs.getDouble('wind_speed_threshold') ?? 10.0;
        precipitationProbabilityThreshold =
            prefs.getDouble('precipitation_probability_threshold') ?? 50.0;
      }
    });

    // Initialize recommended documents with selected locations
    recommendedDocuments = documentService.fetchDocuments(
      4.0, 
      10.0, 
      false, 
      true, 
      _selectedLocations
    );
  }

  Future<void> _initializePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      windSpeedThreshold =
          sharedPreferences.getDouble('wind_speed_threshold') ?? 50.0;
      precipitationProbabilityThreshold =
          sharedPreferences.getDouble('precipitation_probability_threshold') ??
              100.0;
      showUnavailableSlots =
          sharedPreferences.getBool('show_unavailable_courts') ?? true;
      _selectedLocations = 
          sharedPreferences.getStringList('selected_locations') ?? [];
    });
    _fetchDocuments();
  }

  void _fetchDocuments() {
    futureDocuments = documentService.fetchDocuments(
      windSpeedThreshold,
      precipitationProbabilityThreshold,
      showUnavailableSlots,
      false,
      _selectedLocations,
    );
  }

  Future<void> updateThresholds() async {
    try {
      if (sharedPreferences.getString("user_consent") == "all") {
        await sharedPreferences.setDouble(
            'wind_speed_threshold', windSpeedThreshold);
        await sharedPreferences.setDouble('precipitation_probability_threshold',
            precipitationProbabilityThreshold);
        await sharedPreferences.setBool(
            'show_unavailable_courts', showUnavailableSlots);
      }
      _fetchDocuments();
      setState(() {});
    } catch (e) {
      print('Failed to update thresholds: $e');
    }
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildSettingsDialog(),
    );
  }

  Widget _buildSettingsDialog() {
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Filter'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              _buildSlider('Wind Speed', windSpeedThreshold, 0, 50, (value) {
                setState(() => windSpeedThreshold = value);
              }),
              _buildSlider('Precipitation Probability',
                  precipitationProbabilityThreshold, 0, 100, (value) {
                setState(() => precipitationProbabilityThreshold = value);
              }),
              _buildCheckbox('Show unavailable timeslots', showUnavailableSlots,
                  (value) {
                setState(() => showUnavailableSlots = value ?? false);
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Apply'),
            onPressed: () {
              updateThresholds();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text('$label: ${value.round()}${label == 'Wind Speed' ? ' m/s' : '%'}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max.toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      title: 'PADELTID',
      theme: _buildTheme(context),
      home: Stack(
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 750),
                child: Scaffold(
                  body: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF87CEEB),
                              Color.fromARGB(255, 56, 5, 210),
                            ],
                          ),
                        ),
                      ),
                      CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_showOnboarding)
                            SliverToBoxAdapter(
                              child: OnboardingScreen(
                                onDismiss: (selectedLocations,
                                    windSpeed,
                                    precipitationProbability,
                                    showUnavailableCourts) {
                                  setState(() {
                                    _showOnboarding = false;
                                    _selectedLocations = selectedLocations;
                                    windSpeedThreshold = windSpeed;
                                    precipitationProbabilityThreshold =
                                        precipitationProbability;
                                    showUnavailableSlots =
                                        showUnavailableCourts;
                                  });
                                  updateThresholds();
                                },
                              ),
                            ),
                          //const CustomAppBar(),
                          SliverToBoxAdapter(
                              child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LocationSelector(
                                    onLocationsChanged: (locations) {
                                      setState(() {
                                        _selectedLocations = locations;
                                      });
                                      updateThresholds();
                                    },
                                    initialLocations: _selectedLocations,
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.settings,
                                      color: Colors.white, size: 30),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const AuthGate(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )),
                          SliverRecommendedLV(
                              recommendedDocuments: recommendedDocuments),
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.calendar_month,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'All timeslots',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.tune, color: Colors.white),
                                      onPressed: showSettingsDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildFutureBuilder(),
                              childCount: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureBuilder() {
    return FutureBuilder<List<Document>>(
      future: futureDocuments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final groupedDocuments = _groupDocuments(snapshot.data!);
          if (!consentShown) {
            showConsentSnackbar(context, onlyShowIfNotSet: true);
            consentShown = true;
          }

          return MainListView(groupedDocuments: groupedDocuments);
        } else {
          return const Center(child: Text('No data'));
        }
      },
    );
  }

  Map<String, List<Document>> _groupDocuments(List<Document> documents) {
    final groupedDocuments = <String, List<Document>>{};
    for (var document in documents) {
      groupedDocuments.putIfAbsent(document.date, () => []).add(document);
    }
    return groupedDocuments;
  }

  ThemeData _buildTheme(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFFF7F07),
      primaryContainer: Colors.white,
      onPrimary: Colors.black,
      secondary: const Color(0xFFBBBBBB),
      onSecondary: const Color(0xFFEAEAEA),
      tertiary: const Color(0xFFFF7F07),
      error: const Color(0xFFF32424),
      onError: Colors.white,
      background: Colors.white,
      onBackground: const Color(0xFF505050),
      surface: Colors.white,
      onSurface: Colors.black,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: Color(0xFF87CEEB),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
    );
  }
}

class SliverRecommendedLV extends StatelessWidget {
  const SliverRecommendedLV({Key? key, required this.recommendedDocuments})
      : super(key: key);

  final Future<List<Document>>? recommendedDocuments;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Document>>(
        future: recommendedDocuments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(color: Colors.transparent),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return recommended_lv_holder(documents: snapshot.data!);
          }
        },
      ),
    );
  }
}

class ListViewbuilder extends StatelessWidget {
  const ListViewbuilder({Key? key, required this.documentsForDate})
      : super(key: key);

  final List<Document> documentsForDate;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(thickness: 0.5),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentsForDate.length,
      itemBuilder: (_, index) =>
          DocumentWidget(document: documentsForDate[index]),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
