import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class SubscriptionService {
  static const String _baseUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com';
  static const String _checkSubscriptionUrl = '$_baseUrl/checkSubscription';
  static const String _createSubscriptionUrl = '$_baseUrl/createSubscription';
  static const String _cancelSubscriptionUrl = '$_baseUrl/cancelSubscription';

  static Future<bool> get isSubscribed async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final status = await checkSubscription(user.uid);
      return status['hasSubscription'] == true;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }

  // Check subscription status
  static Future<Map<String, dynamic>> checkSubscription(String userId) async {
    try {
      final uri = Uri.parse(_checkSubscriptionUrl).replace(
        queryParameters: {'userId': userId},
      );

      print('Checking subscription status for user: $userId');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check subscription: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking subscription: $e');
      rethrow;
    }
  }

  // Cancel subscription
  static Future<void> cancelSubscription({
    required String userId,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cancelSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        onSuccess();
      } else {
        onError('Failed to cancel subscription: ${response.statusCode}');
      }
    } catch (e) {
      print('Error canceling subscription: $e');
      onError('Error canceling subscription: $e');
    }
  }

  // Start subscription process
  static Future<void> startSubscription({
    required String userId,
    required BuildContext context,
    required String plan, // 'monthly' or 'yearly'
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      print('Creating checkout session for plan: $plan');
      final response = await http.post(
        Uri.parse(_createSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'plan': plan,
          'createCheckoutSession': true,
          'successUrl': '${html.window.location.origin}/success',
          'cancelUrl': '${html.window.location.origin}/cancel',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['url'];

        // Close loading dialog before navigation
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (checkoutUrl != null) {
          print('Redirecting to checkout URL: $checkoutUrl');
          // Try different methods to redirect
          try {
            html.window.location.assign(checkoutUrl);
          } catch (e) {
            print('Error with assign: $e');
            try {
              html.window.location.href = checkoutUrl;
            } catch (e) {
              print('Error with href: $e');
              try {
                html.window.open(checkoutUrl, '_self');
              } catch (e) {
                print('Error with open: $e');
                throw Exception('Failed to redirect to checkout');
              }
            }
          }
        } else {
          throw Exception('No checkout URL in response');
        }
      } else {
        // Close loading dialog on error
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        throw Exception(
            'Failed to create subscription: ${response.statusCode}');
      }
    } catch (e) {
      print('Error starting subscription: $e');
      // Close loading dialog on error if not already closed
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
