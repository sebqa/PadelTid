import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/notification_item.dart';
import 'notification_history_service.dart';
import 'dart:js' as js;

/// Bridge for web notifications with improved IndexedDB support
class WebNotificationBridge {
  static final WebNotificationBridge _instance =
      WebNotificationBridge._internal();
  factory WebNotificationBridge() => _instance;
  WebNotificationBridge._internal();

  bool _initialized = false;
  Timer? _pollingTimer;

  Future<void> initialize() async {
    if (!kIsWeb || _initialized) return;

    _initialized = true;
    print('WebNotificationBridge initialized with IndexedDB support');

    // First check IndexedDB asynchronously
    await _checkIndexedDBForNotifications();

    // Then check regular localStorage
    await _checkForPendingNotifications();

    // Set up polling timer to check periodically
    _pollingTimer = Timer.periodic(Duration(seconds: 15), (_) async {
      await _checkForPendingNotifications();
    });
  }

  Future<void> _checkIndexedDBForNotifications() async {
    if (!kIsWeb) return;

    try {
      print('Checking IndexedDB for background notifications');
      // This will trigger the JS function that migrates IndexedDB → localStorage
      js.context.callMethod(
          'eval', ['window.checkForBackgroundNotificationsInIndexedDB()']);

      // Wait a moment for the async operation to complete
      await Future.delayed(Duration(milliseconds: 500));

      // Now the localStorage should be populated if there were any notifications
    } catch (e) {
      print('Error checking IndexedDB: $e');
    }
  }

  Future<void> _checkForPendingNotifications() async {
    try {
      // Only proceed if we have pending notifications
      if (!_hasPendingNotifications()) return;

      print('Detected pending notifications in web storage');

      // Get individual notifications from JS
      final notificationsJson = _getPendingNotifications();
      if (notificationsJson == null || notificationsJson.isEmpty) return;

      try {
        // Parse the JSON array of notifications
        final notificationsList = jsonDecode(notificationsJson) as List;
        if (notificationsList.isEmpty) return;

        print('Retrieved ${notificationsList.length} individual notifications');

        // Process each notification
        for (final item in notificationsList) {
          try {
            final notificationData = item as Map<String, dynamic>;

            // Create a notification item
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
                notificationData['timestamp'] ??
                    DateTime.now().millisecondsSinceEpoch);

            final title = notificationData['title'] ?? 'New Notification';
            final body = notificationData['body'] ?? '';
            final documentId = notificationData['documentId'];

            // Generate a consistent ID
            final id =
                'doc_${documentId}_${timestamp.millisecondsSinceEpoch}_${(title.hashCode ^ body.hashCode).abs()}';

            final notification = NotificationItem(
              id: id,
              title: title,
              body: body,
              documentId: documentId,
              timestamp: timestamp,
              isRead: false,
            );

            // Add to notification history
            await NotificationHistoryService().addNotification(notification);
            print(
                'Added individual notification: $title for document: $documentId');
          } catch (e) {
            print('Error processing individual notification: $e');
          }
        }

        // We've processed all notifications, so they're already cleared
      } catch (e) {
        print('Error parsing notifications JSON: $e');
      }
    } catch (e) {
      print('Error checking for pending web notifications: $e');
    }
  }

  bool _hasPendingNotifications() {
    if (!kIsWeb) return false;

    try {
      final result =
          js.context.callMethod('eval', ['window.hasPendingNotifications()']);
      return result == true;
    } catch (e) {
      print('Error checking pending notifications: $e');
      return false;
    }
  }

  String? _getPendingNotifications() {
    if (!kIsWeb) return null;

    try {
      // Use the sync version for direct JS interop
      final result = js.context
          .callMethod('eval', ['window.getPendingNotificationsSync()']);

      // Also trigger the async version for next time
      js.context.callMethod('eval', ['window.getPendingNotifications()']);

      return result?.toString();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return null;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
