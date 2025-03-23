import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/document.dart';
import '../pages/document_details_page.dart';
import '../services/document_service.dart';
import 'dart:html' as html;

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();

  factory NotificationHandler() {
    return _instance;
  }

  NotificationHandler._internal();

  void initialize(BuildContext context) {
    if (kIsWeb) {
      // Set up a listener for messages from the service worker
      // This requires dart:html, which we'll use conditionally
      _setupWebMessageListener(context);
    }
  }

  void _setupWebMessageListener(BuildContext context) {
    // Use dart:html conditionally to avoid issues on non-web platforms
    if (kIsWeb) {
      // This code will only run on web
      // ignore: undefined_prefixed_name
      html.window.addEventListener('message', (html.Event event) {
        // Cast to MessageEvent to access data property
        if (event is html.MessageEvent) {
          final dynamic data = event.data;

          if (data is Map && data['type'] == 'NOTIFICATION_CLICK') {
            print('Received notification click message: $data');

            if (data['documentId'] != null) {
              // Navigate to document details page with just the ID
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DocumentDetailsPage(
                    documentId: data['documentId'],
                  ),
                ),
              );
            }
          }
        }
      });
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
