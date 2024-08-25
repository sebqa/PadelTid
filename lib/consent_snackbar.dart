import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

showConsentSnackbar(BuildContext context,
  {bool onlyShowIfNotSet = true}) async {
final prefs = await SharedPreferences.getInstance();
// await prefs.remove('user_consent'); // uncomment to reset for debug purposes
final existingConsentValue = prefs.getString('user_consent');
if (onlyShowIfNotSet && existingConsentValue != null) {
  debugPrint(
      'consent is already set to $existingConsentValue: not showing dialog');
  return;
}
final snackBar = SnackBar(
  content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Your privacy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        RichText(
            text: TextSpan(
                style: const TextStyle(
                    color: Colors.white, fontStyle: FontStyle.italic),
                children: [
              const TextSpan(text: 'By clicking '),
              const TextSpan(
                  text: 'Accept all Cookies',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text: ', you agree that we can store cookies '
                      'on your device and disclose information in accordance with our '),
              TextSpan(
                  text: 'Cookie Policy.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(Uri.parse(
                        'https://padeltid.dk/cookie_policy.html'))), // use your own instead
            ])),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('user_consent', 'all');
                debugPrint(
                    'user_consent is now set to ${prefs.getString('user_consent')}');
              },
              child: const Text('Accept all cookies'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('user_consent', 'only-essential');
                debugPrint(
                    'user_consent is now set to ${prefs.getString('user_consent')}');
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey)),
              child: const Text('Only essential cookies',
                  style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ]),
  duration: const Duration(seconds: 9999999), // do not auto-close
);
ScaffoldMessenger.of(context).showSnackBar(snackBar);
}