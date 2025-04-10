import 'package:flutter/material.dart';
import '../model/notification_item.dart';
import '../services/notification_history_service.dart';
import 'document_details_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final notificationService =
        Provider.of<NotificationHistoryService>(context);
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllNotifications();
                } else if (value == 'mark_all_read') {
                  notificationService.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('All notifications marked as read')));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text('Mark all as read'),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Clear all'),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationItem notification) {
    final notificationService =
        Provider.of<NotificationHistoryService>(context, listen: false);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Remove the notification
        setState(() {
          notificationService.removeNotification(notification.id);
        });
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey.shade200
              : Theme.of(context).primaryColor,
          child: Icon(
            Icons.notifications,
            color: notification.isRead ? Colors.grey : Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy - HH:mm').format(notification.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // Mark as read
          notificationService.markAsRead(notification.id);

          // Navigate to document if available
          if (notification.documentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentDetailsPage(
                  documentId: notification.documentId,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _clearAllNotifications() async {
    // Confirm with the user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear all notifications?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Use the improved method that clears everything
      await NotificationHistoryService().clearAllNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications cleared')),
      );
    }
  }
}

// Add a temporary localization class
class AppLocalizations {
  final BuildContext context;

  AppLocalizations(this.context);

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(context);
  }

  String get clearNotifications => 'Clear all notifications?';
  String get confirmClearNotifications => 'This action cannot be undone.';
  String get cancel => 'CANCEL';
  String get confirm => 'CONFIRM';
  String get notificationsCleared => 'All notifications cleared';
}
