import 'package:flutter/material.dart';
import 'package:flutter_application_1/login_page.dart';

import 'location_select.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      title: SizedBox(
        
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                Icon(Icons.location_pin, color: Theme.of(context).colorScheme.primaryContainer),
                MultiSelectSearchRequestDropdown(),
          ],
        ),
      ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primaryContainer),
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
