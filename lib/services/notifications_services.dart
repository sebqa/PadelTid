import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  Future<void> listenNotifications() async {
    FirebaseMessaging.onMessage.listen(_showFlutterNotification);
  }

  void _showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    //add a toast
print(notification?.title ?? '');
print(notification?.body ?? '');
  }

  Future<String> getToken() async {
FirebaseMessaging.instance.getToken().then((value) {
  String? token = value;
  print(token);
}).onError((error, stackTrace) {
  print(error);
});
    return await FirebaseMessaging.instance.getToken() ?? '';

  }
}

