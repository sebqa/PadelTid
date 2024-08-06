import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MaterialApp(home:HomePage(prefs:prefs)));
}