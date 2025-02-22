import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Update status bar style to use primary color
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: const Color(0xFF00875A), // Use primary color
    statusBarIconBrightness: Brightness.light, // White icons for dark background
    statusBarBrightness: Brightness.dark, // Dark status bar for light icons
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize token service and save token on app launch
  if (FirebaseAuth.instance.currentUser != null) {
    final tokenService = TokenService();
    await tokenService.saveToken();
  }

  //Ask permission for notifications
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  messaging.onTokenRefresh.listen((fcmToken) {
    // TODO: If necessary send token to application server.
    print(fcmToken);
  }).onError((err) {
    // Error getting token.
    print(err);
  });
  //listen for notifications

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print(
          'Message also contained a notification: ${message.notification?.body}');
    }
  });
  runApp(MaterialApp(
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
  ));
}
