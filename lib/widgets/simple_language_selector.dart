import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/translations.dart';

class SimpleLanguageSelector extends StatelessWidget {
  const SimpleLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    // Debug
    print('=== SIMPLE LANGUAGE SELECTOR ===');
    print('Current locale: $currentLocale');

    // Test if translations are working
    final testKeys = ['monday', 'tuesday', 'slots', 'jan', 'feb'];
    for (final key in testKeys) {
      final value = TranslationHelper.translate(key, currentLocale);
      print('Key: $key -> "$value"');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
  }
}
