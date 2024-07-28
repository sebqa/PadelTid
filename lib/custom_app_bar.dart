import 'package:flutter/material.dart';

import 'location_select.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      
      backgroundColor: Theme.of(context).colorScheme.primary,
                title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Baseline(
                    baselineType: TextBaseline.alphabetic,
                    baseline: 28.0, // Adjust this value as needed
                    child: Text(
                      'PADEL',
                      style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.normal,
    fontFamily: 'Roboto',
    color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Baseline(
                    baselineType: TextBaseline.alphabetic,
                    baseline: 28.0, // Same baseline value
                    child: Text(
                      'TID',
                      style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.normal,
    fontFamily: 'Roboto',
    color: Theme.of(context).colorScheme.onPrimary,
    
                      ),
                    ),
                  ),
                 
                ],
              
            ),
            elevation: 0,
            actions: [
              //Make LocationSelect adjust to the size of the screen
              LocationSelect(),
              
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          );
  }
}
