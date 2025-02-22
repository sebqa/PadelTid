import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/login_page.dart';
import 'notification_preferences_dialog.dart';
import 'package:flutter_application_1/services/token_service.dart';

class SubscribingIcon extends StatefulWidget {
  const SubscribingIcon({Key? key, required this.document}) : super(key: key);

  final Document document;

  @override
  State<SubscribingIcon> createState() => _SubscribingIconState();
}

class _SubscribingIconState extends State<SubscribingIcon> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool subscribing = false;
  final TokenService _tokenService = TokenService();

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

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to subscribe to timeslots'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthGate()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NotificationPreferencesDialog(
          initialPreferences: NotificationPreferences(),
          onSave: (preferences) {
            setState(() {
              subscribing = true;
            });

            final user = FirebaseAuth.instance.currentUser!;
            final fcmToken = getFCMToken(user.uid);
            subscribeToTopic(
              widget.document, 
              'true', 
              user,
              preferences,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 1),
                content: Text('Subscribed to timeslot'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> subscribeToTopic(
      Document document, 
      String subscribe,
      User user,
      [NotificationPreferences? preferences]) async {
    try {
      // Get all user tokens
      final tokens = await _tokenService.getUserTokens(user.uid);
      if (tokens.isEmpty) {
        // If no tokens, save current token
        await _tokenService.saveToken();
        tokens.add(await FirebaseMessaging.instance.getToken() ?? '');
      }

      final queryParams = {
        'date': document.date,
        'time': '${document.time}:00',
        'subscribe': subscribe,
        'device_tokens': json.encode(tokens), // Send all tokens
        'userId': user.uid,
        if (preferences != null) 'preferences': json.encode(preferences.toJson()),
      };

      final url = Uri.parse(
          "https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/subTopic")
          .replace(queryParameters: queryParams);

      final response = await http.get(url);

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
    } catch (e) {
      print('Error in subscribeToTopic: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        subscribing ? Icons.notifications : Icons.notifications_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) {
          _showLoginDialog();
          return;
        }

        if (subscribing) {
          setState(() {
            subscribing = false;
          });
          subscribeToTopic(widget.document, 'false', user);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 1),
              content: Text('No longer subscribed to timeslot'),
            ),
          );
        } else {
          _showSubscriptionDialog();
        }
      },
    );
  }
}
