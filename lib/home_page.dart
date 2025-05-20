import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/consent_snackbar.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/painters/tennis_ball_painter.dart';
import 'widgets/skeleton_widgets.dart';
import 'package:provider/provider.dart';
import 'services/notification_history_service.dart';
import 'pages/notifications_page.dart';
import 'package:flutter_application_1/document_service.dart';
import 'login_page.dart';
import 'document_widget.dart';
import 'main_list_view.dart';
import 'recommended_lv_holder.dart';
import 'location_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/token_service.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:flutter_application_1/services/notification_handler.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:flutter_application_1/widgets/subscription_dialogs.dart';
import 'package:flutter_application_1/providers/subscription_provider.dart';

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
  double windSpeedThreshold = 20.0;
  double precipitationProbabilityThreshold = 100.0;
  double temperatureThreshold = 0.0;
  // Notification-specific preferences
  double notificationWindSpeedThreshold = 50.0;
  double notificationPrecipitationThreshold = 100.0;
  double notificationTemperatureThreshold = 0.0;
  bool notificationShowUnavailableSlots = true;
  bool showUnavailableSlots = true;
  bool notifyOnMatchingCourts = false;
  late SharedPreferences sharedPreferences;
  late Future<Map<String, List<Document>>> allDocumentsFuture;
  bool _documentsLoaded = false;
  bool consentShown = false;
  bool _showOnboarding = false;
  List<String> _selectedLocations = [];
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TokenService _tokenService = TokenService();
  late LocaleProvider localeProvider;
  final DocumentService documentService = DocumentService();
  bool _isInitialized = false; // Add flag to track initialization
  Map<String, List<Document>>? _cachedDocuments; // Add cache for documents

  @override
  void initState() {
    super.initState();
    print('[HomePage] initState called');
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
    _initializeApp();
    _tokenService.initTokenRefreshListener();
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    // Initialize notification handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[HomePage] postFrameCallback executed');
      NotificationHandler().initialize(context);
      print(
          '[HomePage] Attempting to get SubscriptionProvider and check status');
      try {
        final provider =
            Provider.of<SubscriptionProvider>(context, listen: false);
        print('[HomePage] Got SubscriptionProvider instance: $provider');
        provider.checkSubscriptionStatus();
      } catch (e) {
        print('[HomePage] ERROR accessing SubscriptionProvider: $e');
      }
    });

    // Initialize notification history service
    Provider.of<NotificationHistoryService>(context, listen: false)
        .initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Token is now only saved during initialization, not on resume
  }

  Future<void> _initializeApp() async {
    // Get shared preferences instance
    sharedPreferences = await SharedPreferences.getInstance();

    // Check onboarding status
    final hasSeenOnboarding =
        sharedPreferences.getString("user_consent") == "all";
    setState(() {
      _showOnboarding = !hasSeenOnboarding;
    });

    // Initialize preferences
    setState(() {
      _selectedLocations =
          sharedPreferences.getStringList('selected_locations') ?? [];

      // Only set default values if not seen onboarding
      if (!_showOnboarding) {
        windSpeedThreshold =
            sharedPreferences.getDouble('wind_speed_threshold') ?? 10.0;
        precipitationProbabilityThreshold = sharedPreferences
                .getDouble('precipitation_probability_threshold') ??
            50.0;
        temperatureThreshold =
            sharedPreferences.getDouble('temperature_threshold') ?? 0.0;
        showUnavailableSlots =
            sharedPreferences.getBool('show_unavailable_courts') ?? true;
        notifyOnMatchingCourts =
            sharedPreferences.getBool('notify_on_matching_courts') ?? false;

        // Load notification preferences or use regular preferences as defaults
        notificationWindSpeedThreshold =
            sharedPreferences.getDouble('notification_wind_threshold') ??
                windSpeedThreshold;
        notificationPrecipitationThreshold = sharedPreferences
                .getDouble('notification_precipitation_threshold') ??
            precipitationProbabilityThreshold;
        notificationTemperatureThreshold =
            sharedPreferences.getDouble('notification_temperature_threshold') ??
                temperatureThreshold;
        notificationShowUnavailableSlots =
            sharedPreferences.getBool('notification_show_unavailable_courts') ??
                showUnavailableSlots;
      }
    });

    // Save token on app launch if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      _tokenService.saveToken();
    }

    // Fetch documents only once initially
    await _fetchDocumentsIfNeeded(forceRefresh: true);

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    setState(() {
      _selectedLocations = prefs.getStringList('selected_locations') ?? [];
      _showOnboarding = !hasSeenOnboarding;
    });
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
      notifyOnMatchingCourts =
          sharedPreferences.getBool('notify_on_matching_courts') ?? false;

      // Load notification preferences or use regular preferences as defaults
      notificationWindSpeedThreshold =
          sharedPreferences.getDouble('notification_wind_threshold') ??
              windSpeedThreshold;
      notificationPrecipitationThreshold =
          sharedPreferences.getDouble('notification_precipitation_threshold') ??
              precipitationProbabilityThreshold;
      notificationTemperatureThreshold =
          sharedPreferences.getDouble('notification_temperature_threshold') ??
              temperatureThreshold;
      notificationShowUnavailableSlots =
          sharedPreferences.getBool('notification_show_unavailable_courts') ??
              showUnavailableSlots;

      _selectedLocations =
          sharedPreferences.getStringList('selected_locations') ?? [];
    });
  }

  Future<void> _fetchDocumentsIfNeeded({bool forceRefresh = false}) async {
    if (forceRefresh || _cachedDocuments == null) {
      print('[HomePage] Fetching documents (force=$forceRefresh)');

      setState(() {
        allDocumentsFuture = documentService.fetchAllDocuments(
          windSpeedThreshold,
          precipitationProbabilityThreshold,
          temperatureThreshold,
          showUnavailableSlots,
          _selectedLocations,
          notifyOnMatchingCourts: notifyOnMatchingCourts,
          notificationWindThreshold: notificationWindSpeedThreshold,
          notificationPrecipitationThreshold:
              notificationPrecipitationThreshold,
          notificationTemperatureThreshold: notificationTemperatureThreshold,
          notificationShowUnavailableSlots: notificationShowUnavailableSlots,
        );
        _documentsLoaded = true;
      });

      // Cache the results
      try {
        _cachedDocuments = await allDocumentsFuture;
      } catch (e) {
        print('[HomePage] Error caching documents: $e');
      }
    } else {
      print('[HomePage] Using cached documents');
    }
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
        await sharedPreferences.setBool(
            'notify_on_matching_courts', notifyOnMatchingCourts);

        // Save notification preferences if notifications are enabled
        if (notifyOnMatchingCourts) {
          await sharedPreferences.setDouble(
              'notification_wind_threshold', notificationWindSpeedThreshold);
          await sharedPreferences.setDouble(
              'notification_precipitation_threshold',
              notificationPrecipitationThreshold);
          await sharedPreferences.setDouble(
              'notification_temperature_threshold',
              notificationTemperatureThreshold);
          await sharedPreferences.setBool(
              'notification_show_unavailable_courts',
              notificationShowUnavailableSlots);
        }
      }

      // Fetch documents with updated settings
      await _fetchDocumentsIfNeeded(forceRefresh: true);
    } catch (e) {
      print('Failed to update thresholds: $e');
    }
  }

  void showSettingsDialog() {
    print('[HomePage] Opening settings dialog. Current notifyOnMatchingCourts: '
        '[34m$notifyOnMatchingCourts\u001b[0m');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isSubscribed =
                context.watch<SubscriptionProvider>().isSubscribed;
            print(
                '[HomePage] showSettingsDialog: isSubscribed = $isSubscribed');

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationHelper.translate('weather_preferences',
                              localeProvider.locale.languageCode),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSliderWithLabel(
                            context: context,
                            icon: Icons.air,
                            label: TranslationHelper.translate('wind_speed',
                                localeProvider.locale.languageCode),
                            value: windSpeedThreshold,
                            onChanged: (value) {
                              setState(() => windSpeedThreshold = value);
                            },
                            min: 0,
                            max: 20,
                            unit: TranslationHelper.translate(
                                'm_per_s', localeProvider.locale.languageCode),
                          ),
                          const SizedBox(height: 24),
                          _buildSliderWithLabel(
                            context: context,
                            icon: Icons.umbrella,
                            label: TranslationHelper.translate('precipitation',
                                localeProvider.locale.languageCode),
                            value: precipitationProbabilityThreshold,
                            onChanged: (value) {
                              setState(() =>
                                  precipitationProbabilityThreshold = value);
                            },
                            min: 0,
                            max: 100,
                            unit: TranslationHelper.translate('percentage',
                                localeProvider.locale.languageCode),
                          ),
                          const SizedBox(height: 24),
                          _buildSliderWithLabel(
                            context: context,
                            icon: Icons.thermostat,
                            label: TranslationHelper.translate('temperature',
                                localeProvider.locale.languageCode),
                            value: temperatureThreshold,
                            onChanged: (value) {
                              setState(() => temperatureThreshold = value);
                            },
                            min: -10,
                            max: 30,
                            unit: TranslationHelper.translate(
                                'celsius', localeProvider.locale.languageCode),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationHelper.translate('show_unavailable',
                                    localeProvider.locale.languageCode),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Switch(
                                value: showUnavailableSlots,
                                onChanged: (value) {
                                  setState(() => showUnavailableSlots = value);
                                },
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationHelper.translate(
                                    'notify_on_matching_courts',
                                    localeProvider.locale.languageCode),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Switch(
                                value: notifyOnMatchingCourts,
                                onChanged: (value) {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Login Required'),
                                          content: const Text(
                                              'Please login to use notification features'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Login'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AuthGate()),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    setState(
                                        () => notifyOnMatchingCourts = value);
                                  }
                                },
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),

                          // Show notification preference sliders only if notifications are enabled
                          if (notifyOnMatchingCourts) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              TranslationHelper.translate(
                                      'notification_preferences',
                                      localeProvider.locale.languageCode) ??
                                  "Notification Preferences",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              TranslationHelper.translate(
                                      'notification_description',
                                      localeProvider.locale.languageCode) ??
                                  "Set specific weather conditions for notifications. Courts matching these conditions will trigger notifications.",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 24),
                            _buildSliderWithLabel(
                              context: context,
                              icon: Icons.air,
                              label: TranslationHelper.translate(
                                      'notification_wind',
                                      localeProvider.locale.languageCode) ??
                                  "Wind Speed",
                              value: notificationWindSpeedThreshold,
                              onChanged: (value) {
                                setState(() =>
                                    notificationWindSpeedThreshold = value);
                              },
                              min: 0,
                              max: 20,
                              unit: TranslationHelper.translate('m_per_s',
                                  localeProvider.locale.languageCode),
                            ),
                            const SizedBox(height: 24),
                            _buildSliderWithLabel(
                              context: context,
                              icon: Icons.umbrella,
                              label: TranslationHelper.translate(
                                      'notification_precipitation',
                                      localeProvider.locale.languageCode) ??
                                  "Precipitation",
                              value: notificationPrecipitationThreshold,
                              onChanged: (value) {
                                setState(() =>
                                    notificationPrecipitationThreshold = value);
                              },
                              min: 0,
                              max: 100,
                              unit: TranslationHelper.translate('percentage',
                                  localeProvider.locale.languageCode),
                            ),
                            const SizedBox(height: 24),
                            _buildSliderWithLabel(
                              context: context,
                              icon: Icons.thermostat,
                              label: TranslationHelper.translate(
                                      'notification_temperature',
                                      localeProvider.locale.languageCode) ??
                                  "Temperature",
                              value: notificationTemperatureThreshold,
                              onChanged: (value) {
                                setState(() =>
                                    notificationTemperatureThreshold = value);
                              },
                              min: -10,
                              max: 30,
                              unit: TranslationHelper.translate('celsius',
                                  localeProvider.locale.languageCode),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  TranslationHelper.translate(
                                      'notification_show_unavailable',
                                      localeProvider.locale.languageCode),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Switch(
                                  value: notificationShowUnavailableSlots,
                                  onChanged: (value) {
                                    setState(() =>
                                        notificationShowUnavailableSlots =
                                            value);
                                  },
                                  activeColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                          // Add padding at the bottom to account for the sticky buttons
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  // Sticky buttons at the bottom
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TranslationHelper.translate(
                              'cancel', localeProvider.locale.languageCode)),
                        ),
                        const SizedBox(width: 8),
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
                          child: Text(TranslationHelper.translate(
                              'apply', localeProvider.locale.languageCode)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
    print('[HomePage] build method called');

    // Try to access SubscriptionProvider in build to verify it exists
    try {
      final subProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      print(
          '[HomePage] SubscriptionProvider accessed in build: isSubscribed=${subProvider.isSubscribed}');
    } catch (e) {
      print('[HomePage] ERROR accessing SubscriptionProvider in build: $e');
    }

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

          // Main content - add RefreshIndicator here
          RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: false,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    TranslationHelper.translate(
                        'app_title', localeProvider.locale.languageCode),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  actions: [
                    // Notification icon with larger hitbox
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NotificationsPage()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(
                                8.0), // Increase padding for larger touch target
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  size: 28, // Slightly larger icon
                                ),
                                Consumer<NotificationHistoryService>(
                                  builder:
                                      (context, notificationService, child) {
                                    final unreadCount =
                                        notificationService.unreadCount;
                                    return unreadCount > 0
                                        ? Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                unreadCount > 9
                                                    ? '9+'
                                                    : '$unreadCount',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : SizedBox
                                            .shrink(); // Return empty widget when no unread notifications
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                if (_selectedLocations.isNotEmpty && _documentsLoaded) ...[
                  // Show Recommended section only if user is logged in
                  if (FirebaseAuth.instance.currentUser != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          TranslationHelper.translate('recommended',
                              localeProvider.locale.languageCode),
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
                      ),
                    ),
                    // Show loading state or content
                    SliverToBoxAdapter(
                      child: FutureBuilder<Map<String, List<Document>>>(
                        future: allDocumentsFuture,
                        builder: (context, snapshot) {
                          if (_cachedDocuments != null) {
                            // Use cached data if available
                            final recommendedDocs =
                                _cachedDocuments!['recommended'] ?? [];
                            return recommended_lv_holder(
                                documents: recommendedDocs);
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return RecommendedListSkeleton();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            final recommendedDocs =
                                snapshot.data!['recommended'] ?? [];
                            return recommended_lv_holder(
                                documents: recommendedDocs);
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ],

                  // Show All Timeslots section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TranslationHelper.translate('all_timeslots',
                                localeProvider.locale.languageCode),
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
                    child: FutureBuilder<Map<String, List<Document>>>(
                      future: allDocumentsFuture,
                      builder: (context, snapshot) {
                        if (_cachedDocuments != null) {
                          // Use cached data if available
                          final filteredDocs =
                              _cachedDocuments!['filtered'] ?? [];
                          final groupedDocuments =
                              _groupDocuments(filteredDocs);
                          if (!consentShown) {
                            showConsentSnackbar(context,
                                onlyShowIfNotSet: true);
                            consentShown = true;
                          }
                          return MainListView(
                            groupedDocuments: groupedDocuments,
                            onFilterTap: showSettingsDialog,
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return MainListSkeleton();
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  '${TranslationHelper.translate('error_prefix', localeProvider.locale.languageCode)} ${snapshot.error}'));
                        } else if (snapshot.hasData) {
                          final filteredDocs = snapshot.data!['filtered'] ?? [];
                          final groupedDocuments =
                              _groupDocuments(filteredDocs);
                          if (!consentShown) {
                            showConsentSnackbar(context,
                                onlyShowIfNotSet: true);
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
                          TranslationHelper.translate('select_clubs',
                              localeProvider.locale.languageCode),
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
    await _fetchDocumentsIfNeeded(forceRefresh: true);
  }
}

class SliverRecommendedLV extends StatelessWidget {
  const SliverRecommendedLV({Key? key, required this.allDocumentsFuture})
      : super(key: key);

  final Future<Map<String, List<Document>>>? allDocumentsFuture;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, List<Document>>>(
        future: allDocumentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return RecommendedListSkeleton();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final recommendedDocs = snapshot.data!['recommended'] ?? [];
            return recommended_lv_holder(documents: recommendedDocs);
          } else {
            return const SizedBox.shrink();
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
