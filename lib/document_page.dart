import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'dart:js' as js;
import 'package:http/http.dart' as http;



class DocumentPage extends StatefulWidget {


  final Document document;

  DocumentPage({required this.document});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  bool subscribing = false;
  final Uri _url = Uri.parse('https://holbaekpadel.dk/da/new/booking');



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.document.date),
      ),
      body: SafeArea(
        child: Column(
          children: [
             Center(
            child: Text(widget.document.date),
          ),
          //add a text with hyperlink to google.com
          Center(
            child: Text(widget.document.symbolCode),
          ),
          Center(
            child: Text(widget.document.time),
          ),
           ElevatedButton(
                  onPressed: () => js.context.callMethod('open', [_url.toString()])
            ,
                  child: Text('Go to court booking'),
                ),
            StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return IconButton(
                icon: Icon(subscribing ? Icons.star : Icons.star_border,color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  //goto login page
                  Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthGate()),
          );
                },
              );
              }
                  print(FirebaseAuth.instance.currentUser!.uid);
            
                  final userId = FirebaseAuth.instance.currentUser!.uid;
            
              return subscribingIcon(document: widget.document, userId: userId);
            },
                  ),
          ],
        ),
      )
    );
  }

  
}

class subscribingIcon extends StatefulWidget {
  const subscribingIcon({
    super.key,
    required this.document,
    required this.userId,
  });

  final Document document;
  final String userId;

  @override
  State<subscribingIcon> createState() => _subscribingIconState();
}

class _subscribingIconState extends State<subscribingIcon> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  bool subscribing = false;
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
  subscribeToTopic(Document document, Future<String> fcmToken, String subscribe) async {
    //make a get request to url
    String token = await fcmToken;
    print(token);
    String url = "https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/subTopic?date=${document.date}&time=${document.time}&subscribe=$subscribe&device_token=${token}&userId=${widget.userId}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      String subscribed = response.body;
      //create JSON object from response.body
      Map<String, dynamic> jsonData = json.decode(subscribed);
      if (jsonData['subscribe'] == 'true') {
        print('Subscribed to topic '+document.date.replaceAll("-", "")+document.time.replaceAll(":", ""));
      } else {
        print("Unsubscribed from topic "+document.date.replaceAll("-", "")+document.time.replaceAll(":", ""));
      }
    } else {
      throw Exception('Failed to subscribe to topic');
    }

  }
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(subscribing ? Icons.star : Icons.star_border,color: Theme.of(context).colorScheme.primary,),
      onPressed: () {
        setState(() {
          subscribing = !subscribing;
        });
                
        //with fcm, subscribe to the topic
        final fcmToken = getFCMToken(widget.userId);
        //subscribe to the topic


        subscribeToTopic(widget.document, fcmToken, subscribing ? 'true' : 'false');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              subscribing ? 'Subscribed to timeslot' : 'No longer subscribed to timeslot',
            ),
          ),
        );
      },
    );
  }
}
