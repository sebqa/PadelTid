import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SubscriptionService {
  static const String _createSubscriptionUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/createSubscription';
  static const String _checkSubscriptionUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/checkSubscription';
  static const String _cancelSubscriptionUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/cancelSubscription';

  // Check subscription status
  static Future<Map<String, dynamic>> checkSubscription(String userId) async {
    final response = await http.get(
      Uri.parse('$_checkSubscriptionUrl?userId=$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check subscription: ${response.body}');
    }
  }

  // Cancel subscription
  static Future<void> cancelSubscription({
    required String userId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('Cancelling subscription...');
      final response = await http.post(
        Uri.parse(_cancelSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          onSuccess();
        } else {
          throw Exception(data['error'] ?? 'Failed to cancel subscription');
        }
      } else {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      print('Error in cancelSubscription: $e');
      onError(e.toString());
    }
  }

  // Start subscription process
  static Future<void> startSubscription({
    required String userId,
    required String plan,
    required Function onSuccess,
    required Function(String) onError,
    required BuildContext context,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    bool isDialogShowing = true;
    Timer? statusCheckTimer;

    try {
      // Show loading indicator in a new overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      print('Creating checkout session...');
      // Create checkout session
      final response = await http.post(
        Uri.parse(_createSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'plan': plan,
          'createCheckoutSession': true,
          'successUrl': '${Uri.base.origin}/#/subscription-success',
          'cancelUrl': '${Uri.base.origin}/#/subscription-cancel',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkoutUrl = data['url'];
        print('Checkout URL: $checkoutUrl');

        // Launch URL using url_launcher
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          // For web, we need to handle the success/cancel URLs
          if (kIsWeb) {
            // Launch the URL in the same tab
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );

            // Start polling for subscription status
            statusCheckTimer =
                Timer.periodic(Duration(seconds: 5), (timer) async {
              try {
                final subscriptionStatus = await checkSubscription(userId);
                if (subscriptionStatus['isActive'] == true) {
                  timer.cancel();
                  if (isDialogShowing && navigatorKey.currentContext != null) {
                    Navigator.of(navigatorKey.currentContext!).pop();
                    isDialogShowing = false;
                  }
                  onSuccess();
                }
              } catch (e) {
                print('Error checking subscription status: $e');
              }
            });

            // Set a timeout for the polling
            Timer(Duration(minutes: 10), () {
              statusCheckTimer?.cancel();
              if (isDialogShowing && navigatorKey.currentContext != null) {
                Navigator.of(navigatorKey.currentContext!).pop();
                isDialogShowing = false;
              }
              onError('Subscription check timed out');
            });
          } else {
            // For non-web platforms, just launch the URL
            await launchUrl(uri);
            onSuccess();
          }
        } else {
          throw Exception('Could not launch $checkoutUrl');
        }
      } else {
        // Dismiss loading indicator if it's still showing
        if (isDialogShowing && navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pop();
          isDialogShowing = false;
        }
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      print('Error in startSubscription: $e');
      // Only dismiss loading indicator if it's still showing
      if (isDialogShowing && navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pop();
        isDialogShowing = false;
      }
      // Cancel the status check timer if it exists
      statusCheckTimer?.cancel();
      onError(e.toString());
    }
  }
}
