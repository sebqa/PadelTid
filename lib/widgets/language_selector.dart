import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;
    final localizations = AppLocalizations.of(context);

    return ListTile(
      title: Text(localizations.translate('language')),
      subtitle: Text(currentLocale == 'en'
          ? localizations.translate('english')
          : localizations.translate('danish')),
      trailing: DropdownButton<String>(
        value: currentLocale,
        onChanged: (String? value) {
          if (value != null) {
            localeProvider.setLocale(Locale(value));
          }
        },
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text(localizations.translate('english')),
          ),
          DropdownMenuItem(
            value: 'da',
            child: Text(localizations.translate('danish')),
          ),
        ],
      ),
    );
  }
}
