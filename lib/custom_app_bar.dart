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
      centerTitle: false,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white, size: 30),
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
