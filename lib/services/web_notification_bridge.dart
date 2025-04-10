import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/notification_item.dart';
import 'notification_history_service.dart';
import 'dart:js' as js;

/// Simple direct bridge for web notifications
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
    print('[WebBridge] Initializing with simplified approach');

    // Check for notifications on startup
    await _processPendingNotifications();

    // Set up polling timer
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await _processPendingNotifications();
    });
  }

  Future<void> _processPendingNotifications() async {
    if (!kIsWeb) return;

    try {
      // Direct JS eval to get notifications, which also initiates IndexedDB check
      final notificationsJson =
          js.context.callMethod('eval', ['window.checkPendingNotifications()']);

      if (notificationsJson == null || notificationsJson.toString().isEmpty) {
        return;
      }

      final List<dynamic> notifications;
      try {
        notifications = jsonDecode(notificationsJson.toString());
        if (notifications.isEmpty) return;

        print('[WebBridge] Processing ${notifications.length} notifications');

        // Process each notification
        for (final notificationData in notifications) {
          if (notificationData is Map<String, dynamic>) {
            await _processNotification(notificationData);
          }
        }

        // Clear processed notifications
        js.context.callMethod('eval', ['window.clearProcessedNotifications()']);
      } catch (e) {
        print('[WebBridge] Error parsing notifications: $e');
      }
    } catch (e) {
      print('[WebBridge] Error retrieving notifications: $e');
    }
  }

  Future<void> _processNotification(Map<String, dynamic> data) async {
    try {
      final notificationHistoryService = NotificationHistoryService();

      // Extract notification data
      final id =
          data['id'] ?? 'notification_${DateTime.now().millisecondsSinceEpoch}';
      final title = data['title'] ?? 'New Notification';
      final body = data['body'] ?? '';
      final documentId = data['documentId'];
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch);

      // Create notification object
      final notification = NotificationItem(
        id: id,
        title: title,
        body: body,
        documentId: documentId,
        timestamp: timestamp,
        isRead: false,
      );

      // Add to notification history
      final added =
          await notificationHistoryService.addNotification(notification);
      print(
          '[WebBridge] Added notification: $added - $title for document $documentId');
    } catch (e) {
      print('[WebBridge] Error processing notification: $e');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
