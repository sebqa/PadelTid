import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/widgets/notification_preferences_dialog.dart';
import 'package:flutter_application_1/services/token_service.dart';
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:flutter_application_1/providers/subscription_provider.dart';
import 'package:provider/provider.dart';

class FollowingIcon extends StatefulWidget {
  const FollowingIcon({Key? key, required this.document}) : super(key: key);

  final Document document;

  @override
  State<FollowingIcon> createState() => _FollowingIconState();
}

class _FollowingIconState extends State<FollowingIcon> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late bool following;
  final TokenService _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    following = widget.document.followed ?? false;
  }

  @override
  void didUpdateWidget(FollowingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.followed != widget.document.followed) {
      setState(() {
        following = widget.document.followed ?? false;
      });
    }
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
          content: const Text('Please login to follow timeslots'),
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
    print('[FollowingIcon] Opening subscription dialog for document: '
        '\u001b[34m${widget.document.date} ${widget.document.time}\u001b[0m');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isSubscribed = context.watch<SubscriptionProvider>().isSubscribed;
        print(
            '[FollowingIcon] _showSubscriptionDialog: isSubscribed = $isSubscribed');
        return NotificationPreferencesDialog(
          initialPreferences: widget.document.notificationPreferences ??
              NotificationPreferences(
                notifyOnWeatherChange: true,
                notifyWhenAvailable: false,
                notifyWhenOneLeft: false,
                notifyWhenFull: false,
              ),
          isSubscribed: isSubscribed,
          onSave: (preferences) {
            final hasAnyPreference = preferences.notifyOnWeatherChange ||
                preferences.notifyWhenAvailable ||
                preferences.notifyWhenOneLeft ||
                preferences.notifyWhenFull;

            setState(() {
              following = hasAnyPreference;
              widget.document.notificationPreferences = preferences;
              widget.document.followed = hasAnyPreference;
            });

            final user = FirebaseAuth.instance.currentUser!;
            followTopic(
              widget.document,
              hasAnyPreference ? 'true' : 'false',
              user,
              preferences,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: Duration(seconds: 1),
                content: Text(hasAnyPreference
                    ? 'Notification preferences updated'
                    : 'No longer following timeslot'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> followTopic(Document document, String follow, User user,
      NotificationPreferences preferences) async {
    try {
      // Get all user tokens
      //final tokens = await _tokenService.getUserTokens(user.uid);
      final tokens = [];

      // Create document ID in the format YYYYMMDDHHMMSS
      final docId = document.date.replaceAll("-", "") +
          document.time.replaceAll(":", "") +
          "00";

      final queryParams = {
        'date': document.date,
        'time': '${document.time}:00',
        'follow': follow,
        'device_tokens': json.encode(tokens),
        'userId': user.uid,
        'id': docId, // Add the document ID
        if (preferences != null)
          'preferences': json.encode(preferences.toJson()),
      };

      final url = Uri.parse(
              "https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/subTopic")
          .replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        String followed = response.body;
        Map<String, dynamic> jsonData = json.decode(followed);
        if (jsonData['follow'] == 'true') {
          print('Following topic ' + docId);
        } else {
          print("No longer following topic " + docId);
        }
      } else {
        throw Exception('Failed to follow topic');
      }
    } catch (e) {
      print('Error in followTopic: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        following ? Icons.notifications : Icons.notifications_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          print('[FollowingIcon] User not logged in, showing login dialog');
          _showLoginDialog();
          return;
        }

        print('[FollowingIcon] User is logged in, showing subscription dialog');
        _showSubscriptionDialog();
      },
    );
  }
}
