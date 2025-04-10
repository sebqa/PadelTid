import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:js' as js;

class NotificationHistoryService extends ChangeNotifier {
  static final NotificationHistoryService _instance =
      NotificationHistoryService._internal();

  factory NotificationHistoryService() {
    return _instance;
  }

  NotificationHistoryService._internal();

  List<NotificationItem> _notifications = [];
  bool _isInitialized = false;

  // Add a static set to track recently processed notification IDs across all instances
  static final Set<String> _recentlyProcessedIds = {};

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize and load notifications from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadNotifications();
    _isInitialized = true;
  }

  // Add this method to check if a notification with the same content exists recently
  bool hasRecentDuplicate(String title, String? documentId,
      {int timeWindowMs = 10000}) {
    final now = DateTime.now();

    // Look for notifications with the same title and documentId in the last timeWindowMs
    return _notifications.any((notification) {
      // Check if title and documentId match
      final isSameContent =
          notification.title == title && notification.documentId == documentId;

      // Check if it was received recently (within timeWindowMs)
      final isRecent =
          now.difference(notification.timestamp).inMilliseconds < timeWindowMs;

      return isSameContent && isRecent;
    });
  }

  // Modify the addNotification method with stronger deduplication
  Future<bool> addNotification(NotificationItem notification) async {
    try {
      print('Adding notification to history: ${notification.title}');

      // Check if notification already exists
      if (_recentlyProcessedIds.contains(notification.id) ||
          _notifications.any((n) => n.id == notification.id)) {
        print('Notification already exists: ${notification.id}');
        return false;
      }

      // Add to static set to prevent duplicates
      _recentlyProcessedIds.add(notification.id);

      // Add to in-memory list
      _notifications.add(notification);

      // Sort by most recent first
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Cap the list size if needed
      if (_notifications.length > 100) {
        _notifications = _notifications.sublist(0, 100);
      }

      // Save to storage
      await _saveNotifications();

      // Notify listeners
      notifyListeners();

      print('Successfully added notification: ${notification.id}');
      return true;
    } catch (e) {
      print('Error adding notification: $e');
      return false;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);

    if (index >= 0) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }

    await _saveNotifications();
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notification_history');

      if (notificationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(notificationsJson);
        _notifications =
            decodedList.map((item) => NotificationItem.fromJson(item)).toList();

        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());

      await prefs.setString('notification_history', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Add this public method to the NotificationHistoryService class
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // Use this method to process notifications from background
  Future<void> processPendingBackgroundNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all background notification keys
      final keys = prefs.getStringList('background_notification_keys') ?? [];

      if (keys.isNotEmpty) {
        print('Found ${keys.length} background notification keys to process');

        for (final key in keys) {
          final jsonData = prefs.getString(key);
          if (jsonData != null) {
            try {
              final data = jsonDecode(jsonData) as Map<String, dynamic>;

              // Generate a consistent ID
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final documentId = data['documentId'];
              final timestamp =
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0);

              final id =
                  'doc_${documentId}_${timestamp.millisecondsSinceEpoch}_${(title.hashCode ^ body.hashCode).abs()}';

              // Create notification item
              final notification = NotificationItem(
                id: id,
                title: title,
                body: body,
                documentId: documentId,
                timestamp: timestamp,
                isRead: false,
              );

              // Add to notification history
              await addNotification(notification);
              print('Processed background notification: $title');

              // Remove the processed notification data
              await prefs.remove(key);
            } catch (e) {
              print('Error processing notification data for key $key: $e');
              // Remove bad data to avoid repeated errors
              await prefs.remove(key);
            }
          }
        }

        // Clear the list of keys after processing
        await prefs.setStringList('background_notification_keys', []);
      }
    } catch (e) {
      print('Error processing background notifications: $e');
    }
  }

  // Clear all notifications from all storage mechanisms
  Future<void> clearAllNotifications() async {
    print('Clearing all notifications from everywhere');

    // 1. Clear in-memory notifications
    _notifications.clear();

    // 2. Clear notifications in SharedPreferences
    await _saveNotifications();

    // 3. Clear notifications in IndexedDB (for web)
    if (kIsWeb) {
      await _clearWebNotifications();
    }

    // 4. Notify listeners that notifications are cleared
    notifyListeners();
  }

  // Helper to clear notifications from IndexedDB (web only)
  Future<void> _clearWebNotifications() async {
    if (!kIsWeb) return;

    try {
      // Call the JS function to clear notifications
      js.context.callMethod('eval',
          ['window.clearAllNotifications && window.clearAllNotifications()']);
      print('Called clearAllNotifications in JS');
    } catch (e) {
      print('Error clearing web notifications: $e');
    }
  }

  // Use this method to mark a notification as read
  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;

      // Also mark as processed in web storage if on web
      if (kIsWeb) {
        try {
          js.context
              .callMethod('eval', ['window.markNotificationProcessed("$id")']);
        } catch (e) {
          print('Error marking web notification as read: $e');
        }
      }

      await _saveNotifications();
      notifyListeners();
    }
  }
}
