import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionProvider with ChangeNotifier {
  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  Future<void> checkSubscriptionStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final data = await SubscriptionService.checkSubscription(userId);
        _isSubscribed =
            data['hasSubscription'] == true && data['status'] == 'active';
      } else {
        _isSubscribed = false;
      }
      notifyListeners();
    } catch (e) {
      _isSubscribed = false;
      notifyListeners();
    }
  }
}
