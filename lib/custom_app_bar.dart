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
      pinned: true,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          'PADELTID',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.black),
      actionsIconTheme: IconThemeData(color: Colors.black),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: Icon(Icons.tune),
            color: Colors.black,
            onPressed: () {
              // Filter action
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: IconButton(
            icon: Icon(Icons.settings),
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AuthGate(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
