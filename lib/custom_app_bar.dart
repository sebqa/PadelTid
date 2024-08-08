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
    //             title: Row(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             children: [
    //               Baseline(
    //                 baselineType: TextBaseline.alphabetic,
    //                 baseline: 28.0, // Adjust this value as needed
    //                 child: Text(
    //                   'PADEL',
    //                   style: TextStyle(
    // fontSize: 28,
    // fontWeight: FontWeight.normal,
    // fontFamily: 'Roboto',
    // color: Theme.of(context).colorScheme.onPrimary,
    //                   ),
    //                 ),
    //               ),
    //               Baseline(
    //                 baselineType: TextBaseline.alphabetic,
    //                 baseline: 28.0, // Same baseline value
    //                 child: Text(
    //                   'TID',
    //                   style: TextStyle(
    // fontSize: 28,
    // fontWeight: FontWeight.normal,
    // fontFamily: 'Roboto',
    // color: Theme.of(context).colorScheme.onPrimary,
    
    //                   ),
    //                 ),
    //               ),
                 
    //             ],
              
    //         ),
            elevation: 0,
            actions: [
              //Make LocationSelect adjust to the size of the screen
              //LocationSelect(),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {

                  //open LoginPage in a dialog
                  
                  //open login page
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
