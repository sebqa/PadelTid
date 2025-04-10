import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../model/notification_item.dart';
import 'notification_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple bridge for web notifications that uses polling and localStorage
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
    print('WebNotificationBridge initialized in simple polling mode');

    // Check for pending notifications immediately
    await _checkForPendingNotifications();

    // Set up polling timer to check every 30 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      await _checkForPendingNotifications();
    });
  }

  Future<void> _checkForPendingNotifications() async {
    try {
      // Check if there are pending notifications using localStorage
      final hasPendingNotifications = await _hasPendingNotifications();

      if (hasPendingNotifications) {
        print('Detected pending notifications in web storage');

        // Generate a simple notification
        final timestamp = DateTime.now();
        final id =
            'background_notification_${timestamp.millisecondsSinceEpoch}';

        final notification = NotificationItem(
          id: id,
          title: 'New Notifications',
          body: 'You have new notifications to view',
          documentId: null, // No specific document
          timestamp: timestamp,
          isRead: false,
        );

        // Add to notification history
        final notificationService = NotificationHistoryService();
        await notificationService.addNotification(notification);

        // Reset the pending count
        _resetPendingNotificationsCount();

        print('Created generic notification for background notifications');
      }
    } catch (e) {
      print('Error checking for pending web notifications: $e');
    }
  }

  bool _hasPendingNotifications() {
    try {
      return html.window.callMethod('hasPendingNotifications') ?? false;
    } catch (e) {
      print('Error checking pending notifications: $e');
      return false;
    }
  }

  void _resetPendingNotificationsCount() {
    try {
      html.window.callMethod('resetPendingNotificationsCount');
    } catch (e) {
      print('Error resetting pending notifications count: $e');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
