import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'document_page.dart';
import 'widgets/subscribing_icon.dart';

class DocumentWidget extends StatefulWidget {
  final Document document;

  DocumentWidget({required this.document});

  @override
  State<DocumentWidget> createState() => _DocumentWidgetState();
}

class _DocumentWidgetState extends State<DocumentWidget> {
  bool _isPressed = false;

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

  static String getWeatherSymbolFromKey(String key) =>
      weatherSymbolKeys[key] ?? 'null';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.document.time,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.thermostat, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${widget.document.airTemperature}°',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(' | ', style: TextStyle(color: Colors.white30)),
                    Icon(Icons.air, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${widget.document.windSpeed}m/s',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white30, size: 16),
                SizedBox(width: 4),
                Text(
                  '${widget.document.totalClubs} location${widget.document.totalClubs != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(' | ', style: TextStyle(color: Colors.white30)),
                Icon(Icons.sports_tennis, color: Colors.white30, size: 16),
                SizedBox(width: 4),
                Text(
                  '${widget.document.totalAvailableSlots} courts',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(' | ', style: TextStyle(color: Colors.white30)),
                Icon(Icons.umbrella, color: Colors.white30, size: 16),
                SizedBox(width: 4),
                Text(
                  '${widget.document.precipitationProbability}%',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
