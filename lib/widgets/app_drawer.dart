import 'package:flutter/material.dart';
import '../widgets/language_selector.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          // Your existing drawer items

          const Divider(),

          // Add language selector
          const LanguageSelector(),

          // Rest of your drawer items
        ],
      ),
    );
  }
}
