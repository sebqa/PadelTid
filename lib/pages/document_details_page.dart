import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';

class DocumentDetailsPage extends StatelessWidget {
  final Document document;

  const DocumentDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

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
          '${_formatDate(document.date, context)} ${TranslationHelper.translate('at', languageCode)} ${document.time}',
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
                    TranslationHelper.translate('overview', languageCode),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined),
                      SizedBox(width: 8),
                      Text(
                          '${document.totalClubs} ${document.totalClubs == 1 ? TranslationHelper.translate('location', languageCode) : TranslationHelper.translate('locations', languageCode)} ${TranslationHelper.translate('available', languageCode)}'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sports_tennis_outlined),
                      SizedBox(width: 8),
                      Text(
                          '${document.totalAvailableSlots} ${document.totalAvailableSlots == 1 ? TranslationHelper.translate('court', languageCode) : TranslationHelper.translate('courts', languageCode)} ${TranslationHelper.translate('available', languageCode)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            TranslationHelper.translate('available_locations', languageCode),
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

  String _formatDate(String date, BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    final documentDate = DateTime.parse(date);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (documentDate.year == now.year &&
        documentDate.month == now.month &&
        documentDate.day == now.day) {
      return TranslationHelper.translate('today', languageCode);
    } else if (documentDate.year == tomorrow.year &&
        documentDate.month == tomorrow.month &&
        documentDate.day == tomorrow.day) {
      return TranslationHelper.translate('tomorrow', languageCode);
    } else {
      final weekday = TranslationHelper.translate(
          [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday'
          ][documentDate.weekday - 1],
          languageCode);

      final month = TranslationHelper.translate(
          [
            'jan',
            'feb',
            'mar',
            'apr',
            'may',
            'jun',
            'jul',
            'aug',
            'sep',
            'oct',
            'nov',
            'dec'
          ][documentDate.month - 1],
          languageCode);

      return '$weekday, $month ${documentDate.day}';
    }
  }

  Widget _buildClubCard(
      BuildContext context, String clubName, ClubAvailability club) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

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
                    '${club.availableSlots}/${club.totalCourts} ${TranslationHelper.translate('courts', languageCode)}',
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
                  '${club.weather.airTemperature}${TranslationHelper.translate('temperature_unit', languageCode)}',
                  TranslationHelper.translate('temperature', languageCode),
                ),
                _buildWeatherInfo(
                  context,
                  Icons.air,
                  '${club.weather.windSpeed}${TranslationHelper.translate('meters_per_second', languageCode)}',
                  TranslationHelper.translate('wind_speed', languageCode),
                ),
                _buildWeatherInfo(
                  context,
                  Icons.water_drop,
                  '${club.weather.precipitationProbability}${TranslationHelper.translate('percent', languageCode)}',
                  TranslationHelper.translate('precipitation', languageCode),
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
                  child: Text(
                      TranslationHelper.translate('book_court', languageCode)),
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
