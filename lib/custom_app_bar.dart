import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/login_page.dart';

import 'location_selector.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      centerTitle: false,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'PADELTID',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            // Filter action
          },
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: Colors.black,
            size: 24,
          ),
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
