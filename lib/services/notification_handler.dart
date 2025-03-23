import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/document.dart';
import '../pages/document_details_page.dart';
import '../services/document_service.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  static BuildContext? _context;

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
            _navigateToDocument(documentId.toString());
          }
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _navigateToDocument(String documentId) {
    if (_context != null) {
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
}
