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
      toolbarHeight: 100,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      title: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.0), // Adjust this value as needed
              child: MultiSelectSearchRequestDropdown(),
            ),
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
