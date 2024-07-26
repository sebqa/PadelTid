import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
                title:  Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
    color: Theme.of(context).colorScheme.primary,
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
    color: Theme.of(context).colorScheme.primary,
    
                      ),
                    ),
                  ),
                ],
              ),
            ),
            elevation: 0,
                );
  }
}
