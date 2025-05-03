import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionProvider with ChangeNotifier {
  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  // Add constructor with logging
  SubscriptionProvider() {
    print('[SubscriptionProvider] Constructor called');
    // Check subscription status on creation
    checkSubscriptionStatus();
  }

  Future<void> checkSubscriptionStatus() async {
    print('[SubscriptionProvider] checkSubscriptionStatus() called');
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('[SubscriptionProvider] Checking subscription status for user: '
          '[34m$userId\u001b[0m');
      if (userId != null) {
        print('[SubscriptionProvider] Making API call to check subscription');
        final data = await SubscriptionService.checkSubscription(userId);
        print('[SubscriptionProvider] SubscriptionService returned: $data');
        _isSubscribed =
            data['hasSubscription'] == true && data['status'] == 'active';
      } else {
        print(
            '[SubscriptionProvider] No user logged in, setting isSubscribed to false');
        _isSubscribed = false;
      }
      print('[SubscriptionProvider] isSubscribed: $_isSubscribed');
      notifyListeners();
    } catch (e) {
      print('[SubscriptionProvider] Error checking subscription: $e');
      _isSubscribed = false;
      notifyListeners();
    }
  }
}
