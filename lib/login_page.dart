import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/secrets/secrets.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
    late DocumentSnapshot documentSnapshot; //Define snapshot

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.of(context).pop(),
        ), 
        title: Text("Account"),
      ),
      body: SafeArea(
        child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            
            return SignInScreen(
              
              providers: [
                EmailAuthProvider(),
                GoogleProvider(clientId: Secrets.clientId),
              ],
              headerBuilder: (context, constraints, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Icon(Icons.account_circle, color: Colors.black,size: 100,),
                  ),
                );
              },
              subtitleBuilder: (context, action) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: action == AuthAction.signIn
                      ? const Text('Welcome to PadelTid, please sign in!')
                      : const Text('Welcome to PadelTid, please sign up!'),
                );
              },
              footerBuilder: (context, action) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
            );
          }
      print(FirebaseAuth.instance.currentUser!.uid);

      final userId = FirebaseAuth.instance.currentUser!.uid;
            setFCMToken(userId);
            //getUserData(userId);

          return AccountScreen(userId);
        },
      ),
      )
      
    );
  }
    
  Future<void> setFCMToken(userId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
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
  print(fcmToken);
    updateUserSettings(userId, "device_token", fcmToken);
  }
}

class AccountScreen extends StatefulWidget {
  final String userId;
  AccountScreen(this.userId, {super.key});



  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  
    bool _notificationsRecommended = false;
    bool _notificationsFollowing = false;
    late DocumentSnapshot documentSnapshot;

void getUserData(userId) async { //use a Async-await function to get the data
    final data =  await FirebaseFirestore.instance.collection('users').doc(userId).get();
    documentSnapshot = data;
    //check if documentSnapshot.data() object has key following
    if(documentSnapshot.data().toString().contains("following")){
      setState(() {
        _notificationsFollowing = documentSnapshot.get("following") ?? false;
      });
    }
    if(documentSnapshot.data().toString().contains("recommended")){
      setState(() {
        _notificationsRecommended = documentSnapshot.get("recommended") ?? false;
      });
    }
    
   
  }

  @override
  Widget build(BuildContext context) {
    getUserData(widget.userId);
    return ProfileScreen(
      actions: [
        SignedOutAction(
          
          (context) => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthGate()),
          ),
        ),
        
      ],
      providers: const [],
      
      children: [
     ToggleSettingsList(
          settings: [
            ToggleSettingWidget(
    enabled: _notificationsFollowing,
    onChanged: (bool value) {
      //set enabled on click
      setState(() {
        _notificationsFollowing = value;
      });
      updateUserSettings(widget.userId, "following", value);
    },
    title: 'Notify on following',
            ),
            ToggleSettingWidget(
    enabled: _notificationsRecommended,
    onChanged: (bool value) {
      setState(() {
        _notificationsRecommended = value;
      });
    updateUserSettings(widget.userId, "recommended", value);
    },
    title: 'Notify on recommended',
            ),
            
          ],
            )
            
          ],  
    );
  }
  
  Future<void> removeFCMToken(userId) async {
    print(userId);
    updateUserSettings(userId, "device_token", "x");
  }

}

Future<void> updateUserSettings(String userId,String s, dynamic value) {

    //firebasefirestore update or add if not existing
    return FirebaseFirestore.instance.collection('users')
    .doc(userId).set({s: value}, SetOptions(merge: true));

  }
class ToggleSettingWidget extends StatefulWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String title;

  const ToggleSettingWidget({
    Key? key,
    required this.enabled,
    required this.onChanged,
    required this.title,
  }) : super(key: key);

  @override
  State<ToggleSettingWidget> createState() => _ToggleSettingWidgetState();
}

class _ToggleSettingWidgetState extends State<ToggleSettingWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
                Text(widget.title),

        Switch(
          value: widget.enabled,
          onChanged: widget.onChanged,
          
        ),
      ],
    );
  }
}

class ToggleSettingsList extends StatelessWidget {
  final List<ToggleSettingWidget> settings;

  const ToggleSettingsList({
    Key? key,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: settings,
    );
  }
}