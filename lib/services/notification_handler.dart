import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/document.dart';
import '../pages/document_details_page.dart';
import '../services/document_service.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import '../model/notification_item.dart';
import '../services/notification_history_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  static BuildContext? _context;

  // Add a simple debounce mechanism
  String? _lastProcessedDocumentId;
  DateTime? _lastProcessedTime;
  static const _debounceTimeMs = 3000; // 3 seconds

  factory NotificationHandler() {
    return _instance;
  }

  NotificationHandler._internal();

  void initialize(BuildContext context) {
    _context = context;
    if (kIsWeb) {
      // Set up a listener for messages from the service worker
      _setupWebMessageListener();

      // Register a global function that can be called from JavaScript
      _registerJsHandlers();
    }
  }

  void _setupWebMessageListener() {
    // Use dart:html conditionally to avoid issues on non-web platforms
    if (kIsWeb) {
      // This code will only run on web
      html.window.addEventListener('message', (html.Event event) {
        // Cast to MessageEvent to access data property
        if (event is html.MessageEvent) {
          print('Received message from service worker: ${event.data}');
          _handleMessage(event.data);
        }
      });

      // Also listen for navigator.serviceWorker.onmessage events
      js.context.callMethod('eval', [
        '''
        if (navigator.serviceWorker) {
          navigator.serviceWorker.addEventListener('message', function(event) {
            window.dispatchEvent(new MessageEvent('message', {
              data: event.data
            }));
          });
        }
      '''
      ]);
    }
  }

  void _registerJsHandlers() {
    // Create a global JS function that Flutter can expose
    js.context['handleNotificationClick'] = (dynamic documentId) {
      print('JS called handleNotificationClick with: $documentId');
      if (documentId != null && _context != null) {
        _navigateToDocument(documentId.toString());
      }
    };
  }

  void _handleMessage(dynamic data) {
    try {
      if (data is Map || data is js.JsObject) {
        final type = data['type'];

        if (type == 'NOTIFICATION_CLICK') {
          final documentId = data['documentId'];
          if (documentId != null && _context != null) {
            // Store this notification and mark as read
            _storeNotification(
              title: 'New Availability',
              body: 'Tap to view available courts',
              documentId: documentId.toString(),
              isRead: true,
            );

            _navigateToDocument(documentId.toString());
          }
        } else if (type == 'NOTIFICATION_RECEIVED') {
          // Store notification when received (not clicked)
          final title = data['title'] ?? 'New Notification';
          final body = data['body'] ?? '';
          final documentId = data['documentId'];
          final timestamp = data['timestamp'];

          // Store this notification as unread
          _storeNotification(
            title: title,
            body: body,
            documentId: documentId?.toString(),
            isRead: false,
            timestamp: timestamp != null
                ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                : DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _navigateToDocument(String documentId) {
    if (_context != null) {
      // Check if this is a duplicate navigation request
      final now = DateTime.now();
      if (_lastProcessedDocumentId == documentId &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds <
              _debounceTimeMs) {
        print(
            'Ignoring duplicate navigation request for document: $documentId');
        return;
      }

      // Update last processed info
      _lastProcessedDocumentId = documentId;
      _lastProcessedTime = now;

      print('Navigating to document: $documentId');

      // Navigate to document details page with just the ID
      Navigator.of(_context!).push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(
            documentId: documentId,
          ),
        ),
      );
    } else {
      print('Cannot navigate: context is null');
    }
  }

  Widget _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );

    return Container(); // Return a dummy widget
  }

  // Store a notification in history
  void _storeNotification({
    required String title,
    required String body,
    String? documentId,
    bool isRead = false,
    DateTime? timestamp,
  }) {
    final notification = NotificationItem(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      documentId: documentId,
      timestamp: timestamp ?? DateTime.now(),
      isRead: isRead,
    );

    NotificationHistoryService().addNotification(notification);
    print('Stored notification: $title (read: $isRead)');
  }
}
