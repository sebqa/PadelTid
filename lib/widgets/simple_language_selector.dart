import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SimpleLanguageSelector extends StatelessWidget {
  const SimpleLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    // Debug
    print('=== SIMPLE LANGUAGE SELECTOR ===');
    print('Current locale: $currentLocale');

    // Test if AppLocalizations is working
    final testKeys = ['monday', 'tuesday', 'slots', 'jan', 'feb'];
    for (final key in testKeys) {
      final value = AppLocalizations.of(context).translate(key);
      print('Key: $key -> "$value"');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            'Current language: ${currentLocale == 'en' ? 'English' : 'Danish'}'),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => localeProvider.setLocale(const Locale('en')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLocale == 'en'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  foregroundColor: currentLocale == 'en'
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                child: const Text('English'),
              ),
              ElevatedButton(
                onPressed: () => localeProvider.setLocale(const Locale('da')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLocale == 'da'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  foregroundColor: currentLocale == 'da'
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Dansk'),
              ),
            ],
          ),
        ),

        // Debug info
        const Divider(),
        const Text('Debug info:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
            'Raw translation of "language": ${AppLocalizations.of(context).translate("language")}'),
        Text(
            'Raw translation of "english": ${AppLocalizations.of(context).translate("english")}'),
        Text(
            'Raw translation of "danish": ${AppLocalizations.of(context).translate("danish")}'),
      ],
    );
  }
}
