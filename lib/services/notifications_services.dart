import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../model/notification_item.dart';
import '../services/notification_history_service.dart';
import 'package:flutter/material.dart';
import '../pages/document_details_page.dart';
import '../main.dart'; // Import to access navigatorKey
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // For web, completely skip Firebase initialization in Flutter code
    if (kIsWeb) {
      print(
          "Web platform - skipping Firebase messaging initialization in Flutter");

      // Set up message listener for web
      _setupWebMessageHandlers();
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
        if (response.payload != null && response.payload!.isNotEmpty) {
          //_handleNotificationClick(null, documentId: response.payload);
        }
      },
    );

    // Listen for Firebase messages on mobile
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set up background message handling for mobile only
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Add this method to handle notification clicks on Android
    setupNotificationClickHandling();

    // Initialize the notification history service
    await NotificationHistoryService().initialize();
  }

  void _setupWebMessageHandlers() {
    // For web, we need to listen for messages from the service worker
    if (kIsWeb) {
      // Listen for push messages from Firebase Cloud Messaging
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Web received foreground message: ${message.messageId}");
        _handleForegroundMessage(message);
      });
    }
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
    final documentId = message.data['documentId'];

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
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: documentId,
      );
    }
  }

  // Helper function to generate consistent notification IDs
  String _generateNotificationId(
      String title, String body, String? documentId, DateTime timestamp) {
    final idBase = documentId != null
        ? 'doc_${documentId}_${timestamp.millisecondsSinceEpoch}'
        : 'notification_${timestamp.millisecondsSinceEpoch}';

    // Add a hash of the content to help with deduplication
    final contentHash = title.hashCode ^ body.hashCode;
    return '${idBase}_${contentHash.abs()}';
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("Handling a foreground message: ${message.messageId}");

    // Extract notification data
    final notification = message.notification;
    final data = message.data;

    // Store in notification history
    if (notification != null) {
      final title = notification.title ?? 'New Notification';
      final body = notification.body ?? '';
      final documentId = data['documentId'];
      final timestamp = DateTime.now();

      final notificationItem = NotificationItem(
        id: _generateNotificationId(title, body, documentId, timestamp),
        title: title,
        body: body,
        documentId: documentId,
        timestamp: timestamp,
      );

      await NotificationHistoryService().addNotification(notificationItem);
      print('Added notification to history: ${notificationItem.title}');
    }

    // Show notification on mobile
    if (!kIsWeb) {
      await _showFlutterNotification(message);
    }
  }

  // Add this method to handle notification clicks on Android
  void setupNotificationClickHandling() {
    if (kIsWeb) return; // Skip for web

    print('Setting up notification click handling for mobile');

    // Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'Notification clicked when app was in background: ${message.messageId}');
      print(
          'Document ID from clicked notification: ${message.data['documentId']}');
      //_handleNotificationClick(message);
    });

    // Check for initial notification that launched the app
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('App launched from notification: ${message.messageId}');
        print(
            'Document ID from launch notification: ${message.data['documentId']}');
        //_handleNotificationClick(message);
      }
    });
/*
    // Set up local notification click handling
    _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Local notification clicked: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          final documentId = response.payload;
          print('Document ID from local notification payload: $documentId');
          _handleNotificationClick(null, documentId: documentId);
        }
      },
    );
*/
  }

  // Handle notification clicks
  void _handleNotificationClick(RemoteMessage? message, {String? documentId}) {
    // Extract document ID from message or use provided one
    String? docId = documentId;

    if (docId == null && message != null) {
      docId = message.data['documentId'];
    }

    if (docId != null) {
      // Mark notification as read
      final notificationService = NotificationHistoryService();

      // Find the notification by document ID
      final notifications = notificationService.notifications
          .where((n) => n.documentId == docId)
          .toList();

      // Mark all matching notifications as read
      if (notifications.isNotEmpty) {
        for (var notification in notifications) {
          notificationService.markAsRead(notification.id);
        }
        print(
            'Marked ${notifications.length} notifications as read for document: $docId');
      } else {
        print('No notifications found for document: $docId');
      }

      // Navigate to document details
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(
            documentId: docId,
          ),
        ),
      );
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase first when handling background messages
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase initialized in background handler");
  } catch (e) {
    print("Failed to initialize Firebase in background handler: $e");
  }

  print("Handling a background message: ${message.messageId}");

  // Store notification in history even for background messages
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    final title = notification.title ?? 'New Notification';
    final body = notification.body ?? '';
    final documentId = data['documentId'];
    final timestamp = DateTime.now();

    try {
      // Initialize the notification history service
      final notificationService = NotificationHistoryService();
      await notificationService.initialize();

      // Use the same ID generation logic
      final id =
          'doc_${documentId}_${timestamp.millisecondsSinceEpoch}_${(title.hashCode ^ body.hashCode).abs()}';

      final notificationItem = NotificationItem(
        id: id,
        title: title,
        body: body,
        documentId: documentId,
        timestamp: timestamp,
      );

      await notificationService.addNotification(notificationItem);
      print(
          'Added background notification to history: ${notificationItem.title}');
    } catch (e) {
      print('Error storing background notification: $e');
    }
  }
}
