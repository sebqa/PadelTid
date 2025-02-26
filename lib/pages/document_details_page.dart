import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class DocumentDetailsPage extends StatelessWidget {
  final Document document;

  const DocumentDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${document.date} at ${document.time}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined),
                      SizedBox(width: 8),
                      Text('${document.totalClubs} locations available'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sports_tennis_outlined),
                      SizedBox(width: 8),
                      Text('${document.totalAvailableSlots} courts available'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Available Locations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          // List of clubs
          ...document.clubs.entries
              .map((entry) => _buildClubCard(context, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildClubCard(
      BuildContext context, String clubName, ClubAvailability club) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clubName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${club.availableSlots}/${club.totalCourts} courts',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Weather information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  context,
                  Icons.thermostat,
                  '${club.weather.airTemperature}°C',
                  'Temperature',
                ),
                _buildWeatherInfo(
                  context,
                  Icons.air,
                  '${club.weather.windSpeed}m/s',
                  'Wind Speed',
                ),
                _buildWeatherInfo(
                  context,
                  Icons.water_drop,
                  '${club.weather.precipitationProbability}%',
                  'Precipitation',
                ),
              ],
            ),
            SizedBox(height: 16),
            // Add book button
            if (club.clubUrl.isNotEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(club.clubUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Book Court'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
