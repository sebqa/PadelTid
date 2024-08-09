import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/login_page.dart';

import 'location_select.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {

@override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Transparent status bar
      statusBarBrightness: Brightness.dark, // Dark text for status bar
    ));  }

  @override
  Widget build(BuildContext context) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Transparent status bar
      statusBarBrightness: Brightness.dark, // Dark text for status bar
    ));
    return SliverAppBar(
      
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: SizedBox(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                Icon(Icons.location_pin),
                MultiSelectSearchRequestDropdown(),
          ],
        ),
      ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                 Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const AuthGate(),
    ),
  );
                },
              ),
            ],
          );
  }
}
