import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // For web, completely skip Firebase initialization in Flutter code
    if (kIsWeb) {
      print(
          "Web platform - skipping Firebase messaging initialization in Flutter");
      return;
    }

    // Only proceed with mobile initialization below
    // Request permissions for mobile
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Mobile-specific initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    // Listen for Firebase messages on mobile only
    //FirebaseMessaging.onMessage.listen(_showFlutterNotification);

    // Set up background message handling for mobile only
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<String> getToken() async {
    // For web, just return empty string or get token from service worker
    if (kIsWeb) {
      return '';
    }

    return await FirebaseMessaging.instance.getToken() ?? '';
  }

  Future<void> _showFlutterNotification(RemoteMessage message) async {
    // Should never be called on web now
    if (kIsWeb) return;

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? 'assets/images/maskable_logo.svg',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 100, 200, 100, 400]),
            sound:
                const RawResourceAndroidNotificationSound('notification_sound'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'notification_sound.aiff',
          ),
        ),
        payload: message.data['url'] ?? '',
      );
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
