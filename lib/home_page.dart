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
import 'RecommendedDocumentWidget.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
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
    return Dialog(
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24),
              _buildSettingsSlider(
                'Wind Speed',
                '${windSpeedThreshold.round()} m/s',
                Icons.air,
                windSpeedThreshold,
                (value) {
                setState(() => windSpeedThreshold = value);
                },
                0,
                20,
              ),
              SizedBox(height: 24),
              _buildSettingsSlider(
                'Precipitation',
                '${precipitationProbabilityThreshold.round()}%',
                Icons.umbrella,
                precipitationProbabilityThreshold,
                (value) {
                setState(() => precipitationProbabilityThreshold = value);
                },
                0,
                100,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Show Unavailable Courts',
                    style: TextStyle(color: Colors.white),
                  ),
                  Switch(
                    value: showUnavailableSlots,
                    onChanged: (value) {
                      setState(() => showUnavailableSlots = value);
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Color(0xFF4A90E2),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      updateThresholds();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSlider(
    String label,
    String value,
    IconData icon,
    double current,
    Function(double) onChanged,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text(label, style: TextStyle(color: Colors.white)),
              ],
            ),
            Text(value, style: TextStyle(color: Colors.white70)),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Color(0xFF4A90E2),
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
          ),
          child: Slider(
            value: current,
          min: min,
          max: max,
          onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                  Color(0xFF4A90E2).withOpacity(0.2),
                  Colors.black,
                            ],
                stops: [0.0, 0.5],
                          ),
                        ),
                      ),
                      CustomScrollView(
                        slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.tune, color: Colors.white),
                    onPressed: () => showSettingsDialog(),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                    ),
                  ),
                ],
              ),
                          SliverToBoxAdapter(
                              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      LocationSelector(
                                    onLocationsChanged: (locations) {
                                      setState(() {
                                        _selectedLocations = locations;
                                      });
                                      updateThresholds();
                                    },
                                    initialLocations: _selectedLocations,
                                  ),
                      SizedBox(height: 24),
                      Row(
                                  children: [
                          Icon(Icons.recommend, color: Colors.white70),
                                          SizedBox(width: 8),
                                          Text(
                            'Recommended',
                                            style: TextStyle(
                              color: Colors.white,
                                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (recommendedDocuments != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: FutureBuilder<List<Document>>(
                      future: recommendedDocuments,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return RecommendedDocumentWidget(
                                snapshot.data![index],
                              );
                            },
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        'All timeslots',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildFutureBuilder(),
              ),
            ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
