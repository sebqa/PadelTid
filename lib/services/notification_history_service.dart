import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_item.dart';
import 'package:flutter/foundation.dart';

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
  Future<void> addNotification(NotificationItem notification,
      {bool checkDuplicates = true}) async {
    // First check if we've recently processed this exact ID
    if (_recentlyProcessedIds.contains(notification.id)) {
      print('Ignoring already processed notification ID: ${notification.id}');
      return;
    }

    // Add to recently processed set with automatic cleanup after 30 seconds
    _recentlyProcessedIds.add(notification.id);
    Future.delayed(Duration(seconds: 30), () {
      _recentlyProcessedIds.remove(notification.id);
    });

    // Check for exact ID duplicates in stored notifications
    final existingIndex =
        _notifications.indexWhere((n) => n.id == notification.id);

    if (existingIndex >= 0) {
      // Update existing notification
      _notifications[existingIndex] = notification;
    } else if (checkDuplicates &&
        hasRecentDuplicate(notification.title, notification.documentId)) {
      // Skip adding if it's a duplicate by content
      print(
          'Skipping duplicate notification by content: ${notification.title}');
      return;
    } else {
      // Add new notification
      _notifications.add(notification);
    }

    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Limit to 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }

    await _saveNotifications();
    notifyListeners();
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

  // Add this method to your NotificationHistoryService class
  Future<void> processPendingBackgroundNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingNotifications =
          prefs.getStringList('pending_background_notifications');

      if (pendingNotifications != null && pendingNotifications.isNotEmpty) {
        print(
            'Processing ${pendingNotifications.length} pending background notifications');

        for (final notificationJson in pendingNotifications) {
          try {
            final map = jsonDecode(notificationJson) as Map<String, dynamic>;

            final notification = NotificationItem(
              id: map['id'],
              title: map['title'],
              body: map['body'],
              documentId: map['documentId'],
              timestamp: DateTime.parse(map['timestamp']),
              isRead: map['isRead'] ?? false,
            );

            await addNotification(notification);
            print('Processed pending notification: ${notification.title}');
          } catch (e) {
            print('Error processing individual notification: $e');
          }
        }

        // Clear the pending list after processing
        await prefs.setStringList('pending_background_notifications', []);
      }
    } catch (e) {
      print('Error processing pending notifications: $e');
    }
  }
}
