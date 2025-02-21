import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
