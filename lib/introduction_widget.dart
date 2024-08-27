import 'package:flutter/material.dart';

class introduction_widget extends StatelessWidget {
  const introduction_widget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to PADELTID',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
               
                Text(
                  'Find your perfect padel court with ease',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                 Row(
                  children: [
                    Icon(Icons.location_pin, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Select your clubs',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.tune, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Filter by the weather you prefer',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sports_baseball, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Browse available courts',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Follow your favorite timeslots for updates',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
