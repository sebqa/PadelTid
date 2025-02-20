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
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF4A90E2),
        secondary: Color(0xFF9CC0E5),
        surface: Colors.white,
        background: Color(0xFFF5F7FA),
        onBackground: Color(0xFF2C3E50),
        onSurface: Color(0xFF2C3E50),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFF2C3E50)),
        titleMedium: TextStyle(color: Color(0xFF2C3E50)),
        bodyLarge: TextStyle(color: Color(0xFF34495E)),
        bodyMedium: TextStyle(color: Color(0xFF34495E)),
      ),
    ),
  ));
}
