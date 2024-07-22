import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MaterialApp(home:HomePage(prefs:prefs)));
}