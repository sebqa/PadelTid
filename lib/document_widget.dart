import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/model/document.dart';
import 'document_page.dart';

class DocumentWidget extends StatelessWidget {
  const DocumentWidget({Key? key, required this.document}) : super(key: key);

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

  static String getWeatherSymbolFromKey(String key) =>
      weatherSymbolKeys[key] ?? 'null';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentPage(document: document),
          ),
        );
        print(result);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildTimeAndWeatherIcon(context),
            SizedBox(width: 12),
            Expanded(child: _buildWeatherInfo(context)),
            _buildSubscriptionIcon(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndWeatherIcon(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          document.time
        ),
        SizedBox(height: 4),
        SizedBox(
          width: 30,
          height: 30,
          child: SvgPicture.asset(
            'assets/weather_symbols/darkmode/${getWeatherSymbolFromKey(document.symbolCode)}.svg',
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildInfoItem(context, Icons.thermostat_outlined, '${document.airTemperature}°C'),
            SizedBox(width: 8),
            _buildInfoItem(context, Icons.air, '${document.windSpeed}m/s'),
            SizedBox(width: 8),
            _buildInfoItem(context, Icons.umbrella, '${document.precipitationProbability}%'),
          ],
        ),
        SizedBox(height: 4),
        _buildAvailableCourts(context),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAvailableCourts(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
      children: [
        Icon(Icons.sports_baseball, size: 14, color: Colors.white),
        SizedBox(width: 2),
        Text(
          '${document.availableSlots} available ${document.availableSlots == 1 ? 'court' : 'courts'}',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
        )
    );
  }

  Widget _buildSubscriptionIcon(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SizedBox(
      width: 40,
      child: user == null
          ? IconButton(
              icon: Icon(Icons.star_border, color: Theme.of(context).colorScheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGate())),
              padding: EdgeInsets.zero,
            )
          : subscribingIcon(document: document, user: user),
    );
  }
}
