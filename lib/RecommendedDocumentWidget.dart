import 'package:flutter/material.dart';
import 'package:flutter_application_1/document_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class RecommendedDocumentWidget extends StatelessWidget {
  final Document document;
  static final weatherSymbolKeys = {
    'clearsky_day': '01d',
    'clearsky_night': '01n',
    'clearsky_polartwilight': '01m',
    'fair_day': '02d',
    'fair_night': '02n',
    'fair_polartwilight': '02m',
    'partlycloudy_day': '03d',
    'partlycloudy_night': '03n',
    'partlycloudy_polartwilight': '03m',
    'cloudy': '04',
    'rainshowers_day': '05d',
    'rainshowers_night': '05n',
    'rainshowers_polartwilight': '05m',
    'rainshowersandthunder_day': '06d',
    'rainshowersandthunder_night': '06n',
    'rainshowersandthunder_polartwilight': '06m',
    'sleetshowers_day': '07d',
    'sleetshowers_night': '07n',
    'sleetshowers_polartwilight': '07m',
    'snowshowers_day': '08d',
    'snowshowers_night': '08n',
    'snowshowers_polartwilight': '08m',
    'rain': '09',
    'heavyrain': '10',
    'heavyrainandthunder': '11',
    'sleet': '12',
    'snow': '13',
    'snowandthunder': '14',
    'fog': '15',
    'sleetshowersandthunder_day': '20d',
    'sleetshowersandthunder_night': '20n',
    'sleetshowersandthunder_polartwilight': '20m',
    'snowshowersandthunder_day': '21d',
    'snowshowersandthunder_night': '21n',
    'snowshowersandthunder_polartwilight': '21m',
    'raininthunder': '22',
    'sleetandthunder': '23',
    'lightrainshowersandthunder_day': '24d',
    'lightrainshowersandthunder_night': '24n',
    'lightrainshowersandthunder_polartwilight': '24m',
    'heavyrainshowersandthunder_day': '25d',
    'heavyrainshowersandthunder_night': '25n',
    'heavyrainshowersandthunder_polartwilight': '25m',
    'lightssleetshowersandthunder_day': '26d',
    'lightssleetshowersandthunder_night': '26n',
    'lightssleetshowersandthunder_polartwilight': '26m',
    'heavysleetshowersandthunder_day': '27d',
    'heavysleetshowersandthunder_night': '27n',
    'heavysleetshowersandthunder_polartwilight': '27m',
    'lightssnowshowersandthunder_day': '28d',
    'lightssnowshowersandthunder_night': '28n',
    'lightssnowshowersandthunder_polartwilight': '28m',
    'heavysnowshowersandthunder_day': '29d',
    'heavysnowshowersandthunder_night': '29n',
    'heavysnowshowersandthunder_polartwilight': '29m',
    'lightrainandthunder': '30',
    'lightsleetandthunder': '31',
    'heavysleetandthunder': '32',
    'lightsnowandthunder': '33',
    'heavysnowandthunder': '34',
    'lightrainshowers_day': '40d',
    'lightrainshowers_night': '40n',
    'lightrainshowers_polartwilight': '40m',
    'heavyrainshowers_day': '41d',
    'heavyrainshowers_night': '41n',
    'heavyrainshowers_polartwilight': '41m',
    'lightsleetshowers_day': '42d',
    'lightsleetshowers_night': '42n',
    'lightsleetshowers_polartwilight': '42m',
    'heavysleetshowers_day': '43d',
    'heavysleetshowers_night': '43n',
    'heavysleetshowers_polartwilight': '43m',
    'lightsnowshowers_day': '44d',
    'lightsnowshowers_night': '44n',
    'lightsnowshowers_polartwilight': '44m',
    'heavysnowshowers_day': '45d',
    'heavysnowshowers_night': '45n',
    'heavysnowshowers_polartwilight': '45m',
    'lightrain': '46',
    'lightsleet': '47',
    'heavysleet': '48',
    'lightsnow': '49',
    'heavysnow': '50',
  };

  static String getWeatherSymbolFromKey(String key) {
    return weatherSymbolKeys[key] ?? 'null';
  }

  RecommendedDocumentWidget(this.document);

  String _getDisplayDate(String date) {
    final now = DateTime.now();
    final documentDate = DateTime.parse(date);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (documentDate.year == now.year &&
        documentDate.month == now.month &&
        documentDate.day == now.day) {
      return 'Today';
    } else if (documentDate.year == tomorrow.year &&
        documentDate.month == tomorrow.month &&
        documentDate.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE, MMM d').format(documentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentPage(document: document),
            ),
          );
        },
        child: Container(
          width: 160,
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    document.time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getDisplayDate(document.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(context, Icons.thermostat,
                      '${document.airTemperature}°C'),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/weather_symbols/darkmode/${getWeatherSymbolFromKey(document.symbolCode)}.svg',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                      context, Icons.air, '${document.windSpeed}m/s'),
                  _buildInfoItem(context, Icons.umbrella,
                      '${document.precipitationProbability}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
