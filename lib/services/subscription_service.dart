import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:js' as js;

class SubscriptionService {
  static const String _createSubscriptionUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/createSubscription';
  static const String _checkSubscriptionUrl =
      'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/checkSubscription';

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

  // Start subscription process
  static Future<void> startSubscription({
    required String userId,
    required String plan,
    required Function onSuccess,
    required Function(String) onError,
    required BuildContext context,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create checkout session
      final response = await http.post(
        Uri.parse(_createSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'plan': plan,
          'createCheckoutSession': true,
          'successUrl': '${js.context['location']['origin']}/#/success',
          'cancelUrl': '${js.context['location']['origin']}/#/cancel',
        }),
      );

      // Dismiss loading indicator
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkoutUrl = data['url'];

        // Redirect to Stripe Checkout using JS
        js.context.callMethod('open', [checkoutUrl, '_self']);
        onSuccess();
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      print('Error in startSubscription: $e');
      // Dismiss loading indicator if still showing
      Navigator.of(context).pop();
      onError(e.toString());
    }
  }
}
