import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize local notifications
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
        // Handle notification taps
        print('Notification tapped: ${response.payload}');
        // You can add navigation logic here
      },
    );

    // Listen for Firebase messages
    FirebaseMessaging.onMessage.listen(_showFlutterNotification);

    // Set up background message handling for mobile only
    // Skip for web since service worker handles background messages
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _showFlutterNotification(RemoteMessage message) async {
    // For web PWA, skip showing this notification if we're in the foreground
    // since the service worker will handle background notifications
    if (kIsWeb) {
      if (message.data['isFromServiceWorker'] == 'true') {
        print('Skipping duplicate notification from service worker');
        return;
      }
    }

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
            icon: android?.smallIcon ?? 'assets/icon/logo', // Use app icon
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(
                [0, 200, 100, 200, 100, 200]), // Enhanced pattern
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

  Future<String> getToken() async {
    return await FirebaseMessaging.instance.getToken() ?? '';
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to handle background notifications specially
  print("Handling a background message: ${message.messageId}");
}
