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
import 'pages/document_details_page.dart';
import 'services/notification_handler.dart';
import 'services/notification_history_service.dart';
import 'services/web_notification_bridge.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_application_1/providers/subscription_provider.dart';

// Add this at the top level
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class RouteGuard extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Route popped: ${route.settings.name}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[main] Starting app initialization');

  // Configure URL strategy for web
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  // Initialize SharedPreferences early
  await SharedPreferences.getInstance();

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
  print('[main] LocaleProvider initialized');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[main] Firebase initialized');

  // Initialize the notification service
  await NotificationService().initialize();
  print('[main] NotificationService initialized');

  // Process any pending background notifications
  final notificationHistoryService = NotificationHistoryService();
  await notificationHistoryService.initialize();
  print('[main] NotificationHistoryService initialized');

  // Initialize web notification bridge for PWAs with polling
  if (kIsWeb) {
    await WebNotificationBridge().initialize();
    print('[main] Using polling-based notification bridge for web');
  } else {
    await notificationHistoryService.processPendingBackgroundNotifications();
  }

  // Perform user auth check and token operations
  if (FirebaseAuth.instance.currentUser != null) {
    print(
        '[main] User is logged in: ${FirebaseAuth.instance.currentUser!.uid}');
    // We're now using TokenService initialize in HomePage, so don't call saveToken here
    // TokenService().saveToken();
  } else {
    print('[main] No user is logged in');
  }

  // Get the initial route from the URL
  String initialRoute = '/';
  if (kIsWeb) {
    final path = Uri.base.path;
    if (path == '/success' ||
        path == '/checkout-cancelled' ||
        path == '/subscription-cancelled') {
      initialRoute = path;
    }
    print('[main] Initial route: $initialRoute');
  }

  // Now launch the full app with everything initialized
  print('[main] Running MultiProvider with SubscriptionProvider');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => localeProvider),
        ChangeNotifierProvider(create: (_) => notificationHistoryService),
        ChangeNotifierProvider(create: (_) {
          print('[main] Creating SubscriptionProvider');
          return SubscriptionProvider();
        }),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class CustomRouteDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final GlobalKey<NavigatorState> navigatorKey;
  String? _currentRoute;

  CustomRouteDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    if (kIsWeb) {
      _currentRoute = Uri.base.path;
      if (_currentRoute!.isEmpty) _currentRoute = '/';
    } else {
      _currentRoute = '/';
    }
  }

  @override
  String? get currentConfiguration => _currentRoute;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        // Always include the root route
        MaterialPage(
          key: const ValueKey('root'),
          child: _currentRoute == '/' ? HomePage() : Container(),
        ),
        // Add the actual route if it's not the root
        if (_currentRoute != '/') ...[
          if (_currentRoute == '/success')
            MaterialPage(
              key: const ValueKey('success'),
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Subscription Successful'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Your subscription was successful!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _currentRoute = '/';
                          notifyListeners();
                        },
                        child: Text('Return to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_currentRoute == '/cancel')
            MaterialPage(
              key: const ValueKey('cancel'),
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Checkout Cancelled'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        color: Colors.orange,
                        size: 100,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'You cancelled the checkout process.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'You can try again anytime.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _currentRoute = '/';
                          notifyListeners();
                        },
                        child: Text('Return to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_currentRoute == '/subscription-cancelled')
            MaterialPage(
              key: const ValueKey('subscription-cancelled'),
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Subscription Cancelled'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 100,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Your subscription has been cancelled.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'You will still have access to premium features until the end of your billing period.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _currentRoute = '/';
                          notifyListeners();
                        },
                        child: Text('Return to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_currentRoute?.startsWith('/document/') ?? false)
            MaterialPage(
              key: ValueKey(_currentRoute),
              child: DocumentDetailsPage(
                documentId: _currentRoute!.split('/').last,
              ),
            ),
        ],
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        _currentRoute = '/';
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    _currentRoute = configuration;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        print('Current locale: ${localeProvider.locale.languageCode}');
        return MaterialApp(
          navigatorKey: navigatorKey,
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
            useMaterial3: false,
            iconTheme: IconThemeData(
              color: Color(0xFF00875A),
              size: 24,
            ),
            primaryIconTheme: IconThemeData(
              color: Colors.white,
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
          initialRoute: initialRoute,
          routes: {
            '/': (context) => HomePage(),
            '/success': (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Subscription Successful'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Your subscription was successful!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: Text('Return to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
            '/checkout-cancelled': (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Checkout Cancelled'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.orange,
                          size: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'You cancelled the checkout process.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'You can try again anytime.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: Text('Return to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
            '/subscription-cancelled': (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Subscription Cancelled'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Your subscription has been cancelled.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'You will still have access to premium features until the end of your billing period.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: Text('Return to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
          },
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/document/') ?? false) {
              final documentId = settings.name?.split('/').last;
              if (documentId != null) {
                return MaterialPageRoute(
                  builder: (context) => DocumentDetailsPage(
                    documentId: documentId,
                  ),
                );
              }
            }
            return null;
          },
        );
      },
    );
  }
}

class RouteInformationParserImpl extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.location ?? '/';
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(location: configuration);
  }
}

// Add this function to handle initial notification
/*Future<void> setupInitialNotificationHandling() async {
  // Only proceed for mobile platforms
  if (kIsWeb) return;

  // Check if app was opened from a notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App was launched by notification: ${initialMessage.messageId}');
    print('Document ID: ${initialMessage.data['documentId']}');

    // Store the documentId to navigate after app is fully initialized
    final documentId = initialMessage.data['documentId'];
    if (documentId != null) {
      // Add a delay to ensure the app is fully initialized
      Future.delayed(Duration(seconds: 1), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DocumentDetailsPage(
              documentId: documentId,
            ),
          ),
        );
      });

      // Mark notification as read
      final notificationService = NotificationHistoryService();
      await notificationService.initialize();

      final notifications = notificationService.notifications
          .where((n) => n.documentId == documentId)
          .toList();

      if (notifications.isNotEmpty) {
        for (var notification in notifications) {
          notificationService.markAsRead(notification.id);
        }
        print(
            'Marked ${notifications.length} notifications as read for document: $documentId');
      }
    }
  }
}*/
