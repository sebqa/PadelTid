import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/model/document.dart';

class SubscribingIcon extends StatefulWidget {
  const SubscribingIcon({Key? key, required this.document, required this.user})
      : super(key: key);

  final Document document;
  final User user;

  @override
  State<SubscribingIcon> createState() => _SubscribingIconState();
}

class _SubscribingIconState extends State<SubscribingIcon> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool subscribing = false;

  @override
  void initState() {
    super.initState();
    subscribing = widget.document.subscribed ?? false;
  }

  Future<String> getFCMToken(userId) async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    final fcmToken = await messaging.getToken(
        vapidKey:
            "BIrzD_lqpWDvg6nMYArPnCbQeg1nqkRT-K4LyCBHahJws-7xceAPI2dDegDA-09TfRt1pIgbtGGETxLas3rAJpw");
    return fcmToken!;
  }

  subscribeToTopic(Document document, Future<String> fcmToken, String subscribe,
      User user) async {
    String token = await fcmToken;
    print(token);
    String? jwt = await user.getIdToken();
    print(jwt);

    String url =
        "https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/subTopic?date=${document.date}&time=${document.time}:00&subscribe=$subscribe&device_token=${token}&userId=${widget.user.uid}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      String subscribed = response.body;
      Map<String, dynamic> jsonData = json.decode(subscribed);
      if (jsonData['subscribe'] == 'true') {
        print('Subscribed to topic ' +
            document.date.replaceAll("-", "") +
            document.time.replaceAll(":", "") +
            '00');
      } else {
        print("Unsubscribed from topic " +
            document.date.replaceAll("-", "") +
            document.time.replaceAll(":", "") +
            '00');
      }
    } else {
      throw Exception('Failed to subscribe to topic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        subscribing ? Icons.star : Icons.star_border,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        setState(() {
          subscribing = !subscribing;
        });

        final fcmToken = getFCMToken(widget.user.uid);
        subscribeToTopic(widget.document, fcmToken,
            subscribing ? 'true' : 'false', widget.user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              subscribing
                  ? 'Subscribed to timeslot'
                  : 'No longer subscribed to timeslot',
            ),
          ),
        );
      },
    );
  }
}
