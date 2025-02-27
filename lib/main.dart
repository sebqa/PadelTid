import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/token_service.dart';
import 'services/notifications_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'navigation/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Update status bar style to use primary color
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: const Color(0xFF00875A), // Use primary color
    statusBarIconBrightness:
        Brightness.light, // White icons for dark background
    statusBarBrightness: Brightness.dark, // Dark status bar for light icons
  ));

  // Initialize the locale provider first and pre-load the current locale
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  // Initialize Firebase in parallel with app loading
  final firebaseInitialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pre-initialize other services in parallel
  final notificationServiceInit = NotificationService().initialize();
  final prefsInit = SharedPreferences.getInstance();

  // Show minimal UI initially while waiting for data
  runApp(LoadingApp());

  // Wait for critical initializations
  await firebaseInitialization;

  // Perform user auth check and token operations
  if (FirebaseAuth.instance.currentUser != null) {
    TokenService().saveToken();
  }

  // Request notification permissions in parallel with app startup
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Now launch the full app when ready
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

// Minimal loading app that renders immediately
class LoadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF00875A),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingDot(delay: 0),
              SizedBox(width: 8),
              LoadingDot(delay: 0.2),
              SizedBox(width: 8),
              LoadingDot(delay: 0.4),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingDot extends StatefulWidget {
  final double delay;
  LoadingDot({required this.delay});

  @override
  _LoadingDotState createState() => _LoadingDotState();
}

class _LoadingDotState extends State<LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        print('Current locale: ${localeProvider.locale.languageCode}');
        return MaterialApp(
          home: HomePage(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: const Color(0xFF00875A), // Match primary color
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: Color(0xFFF8F8F8),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00875A),
              onPrimary: Colors.white,
              secondary: Color(0xFF757575),
              surface: Colors.white,
              background: Color(0xFFF8F8F8),
              onBackground: Color(0xFF1D1D1D),
              onSurface: Color(0xFF1D1D1D),
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1D),
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1D),
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1D),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1D),
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
          ),
          navigatorObservers: [NavigationHelper.routeObserver],
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('da'), // Danish
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
