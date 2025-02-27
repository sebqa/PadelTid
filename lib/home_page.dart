import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/consent_snackbar.dart';
import 'package:flutter_application_1/document_service.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/painters/tennis_ball_painter.dart';
import 'widgets/skeleton_widgets.dart';

import 'login_page.dart';
import 'document_widget.dart';
import 'main_list_view.dart';
import 'recommended_lv_holder.dart';
import 'location_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/token_service.dart';
import 'package:flutter_application_1/widgets/language_selector.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_application_1/widgets/simple_language_selector.dart';

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  double windSpeedThreshold = 50.0;
  double precipitationProbabilityThreshold = 100.0;
  double temperatureThreshold = 0.0;
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
  final TokenService _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _tokenService.initTokenRefreshListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (FirebaseAuth.instance.currentUser != null) {
        _tokenService.saveToken();
      }
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    setState(() {
      _selectedLocations = prefs.getStringList('selected_locations') ?? [];
      _showOnboarding = !hasSeenOnboarding;
      if (!_showOnboarding) {
        windSpeedThreshold = prefs.getDouble('wind_speed_threshold') ?? 10.0;
        precipitationProbabilityThreshold =
            prefs.getDouble('precipitation_probability_threshold') ?? 50.0;
        temperatureThreshold = prefs.getDouble('temperature_threshold') ?? 0.0;
      }
    });

    // Initialize recommended documents with selected locations
    recommendedDocuments = documentService.fetchDocuments(
        windSpeedThreshold,
        precipitationProbabilityThreshold,
        temperatureThreshold,
        false,
        true,
        _selectedLocations);
  }

  Future<void> _initializePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      windSpeedThreshold =
          sharedPreferences.getDouble('wind_speed_threshold') ?? 10.0;
      precipitationProbabilityThreshold =
          sharedPreferences.getDouble('precipitation_probability_threshold') ??
              50.0;
      temperatureThreshold =
          sharedPreferences.getDouble('temperature_threshold') ?? 0.0;
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
      temperatureThreshold,
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
        await sharedPreferences.setDouble(
            'temperature_threshold', temperatureThreshold);
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('weather_preferences'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 24),
                  _buildSliderWithLabel(
                    context: context,
                    icon: Icons.air,
                    label: AppLocalizations.of(context).translate('wind_speed'),
                    value: windSpeedThreshold,
                    onChanged: (value) {
                      setState(() => windSpeedThreshold = value);
                    },
                    min: 0,
                    max: 20,
                    unit: AppLocalizations.of(context).translate('m_per_s'),
                  ),
                  SizedBox(height: 24),
                  _buildSliderWithLabel(
                    context: context,
                    icon: Icons.umbrella,
                    label:
                        AppLocalizations.of(context).translate('precipitation'),
                    value: precipitationProbabilityThreshold,
                    onChanged: (value) {
                      setState(() => precipitationProbabilityThreshold = value);
                    },
                    min: 0,
                    max: 100,
                    unit: AppLocalizations.of(context).translate('percentage'),
                  ),
                  SizedBox(height: 24),
                  _buildSliderWithLabel(
                    context: context,
                    icon: Icons.thermostat,
                    label:
                        AppLocalizations.of(context).translate('temperature'),
                    value: temperatureThreshold,
                    onChanged: (value) {
                      setState(() => temperatureThreshold = value);
                    },
                    min: -10,
                    max: 30,
                    unit: AppLocalizations.of(context).translate('celsius'),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('show_unavailable'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Switch(
                        value: showUnavailableSlots,
                        onChanged: (value) {
                          setState(() => showUnavailableSlots = value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
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
                            AppLocalizations.of(context).translate('cancel')),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          updateThresholds();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                            AppLocalizations.of(context).translate('apply')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderWithLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).toInt(), // This creates steps of 0.1
            onChanged: (newValue) {
              // Round to 1 decimal place
              onChanged(double.parse(newValue.toStringAsFixed(1)));
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Stack(
              children: [
                // Main circle
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ),
                ),
                // Curved lines
                CustomPaint(
                  size: Size(300, 300),
                  painter: TennisBallPainter(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    strokeWidth: 15,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: false,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  AppLocalizations.of(context).translate('app_title'),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings),
                    color: Colors.black,
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
              SliverToBoxAdapter(
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
              if (_selectedLocations.isNotEmpty) ...[
                // Show Recommended section header and content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      AppLocalizations.of(context).translate('recommended'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                              ),
                    ),
                  ),
                ),
                // Show loading state or content
                if (recommendedDocuments != null)
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<Document>>(
                      future: recommendedDocuments,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return RecommendedListSkeleton();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return recommended_lv_holder(
                              documents: snapshot.data ?? []);
                        }
                      },
                    ),
                  ),

                // Show All Timeslots section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('all_timeslots'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                              ),
                        ),
                        IconButton(
                          icon: Icon(Icons.tune, color: Colors.black),
                          onPressed: showSettingsDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // Show loading state or content for All Timeslots
                SliverToBoxAdapter(
                  child: FutureBuilder<List<Document>>(
                    future: futureDocuments,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return MainListSkeleton();
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                '${AppLocalizations.of(context).translate('error_prefix')} ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        final groupedDocuments =
                            _groupDocuments(snapshot.data!);
                        if (!consentShown) {
                          showConsentSnackbar(context, onlyShowIfNotSet: true);
                          consentShown = true;
                        }
                        return MainListView(
                          groupedDocuments: groupedDocuments,
                          onFilterTap: showSettingsDialog,
                        );
                      }
                      return const Center(child: Text('No data'));
                    },
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        AppLocalizations.of(context).translate('select_clubs'),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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

  Future<void> _refreshData() async {
    setState(() {
      futureDocuments = documentService.fetchDocuments(
        windSpeedThreshold,
        precipitationProbabilityThreshold,
        temperatureThreshold,
        showUnavailableSlots,
        false,
        _selectedLocations,
      );

      if (_selectedLocations.isNotEmpty) {
        recommendedDocuments = documentService.fetchDocuments(
            windSpeedThreshold,
            precipitationProbabilityThreshold,
            temperatureThreshold,
            false,
            true,
            _selectedLocations);
      }
    });
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
            return RecommendedListSkeleton();
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
