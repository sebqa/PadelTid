import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/translations.dart';

class AppLocalizations {
  final Locale locale;
  static bool _debugPrinted = false;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final result =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (result == null) {
      if (!_debugPrinted) {
        print(
            'WARNING: AppLocalizations.of() returned null. Falling back to English.');
        _debugPrinted = true;
      }
      return AppLocalizations(const Locale('en'));
    }
    return result;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};
  bool _initialized = false;

  Future<bool> load() async {
    if (_initialized) return true;

    try {
      String jsonString = await rootBundle
          .loadString('assets/l10n/app_${locale.languageCode}.json');

      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      // Fall back if empty
      if (_localizedStrings.isEmpty) {
        _localizedStrings =
            TranslationHelper.getTranslations(locale.languageCode);
      }

      _initialized = true;
      return true;
    } catch (e) {
      // Use fallback translations silently without debug prints
      _localizedStrings =
          TranslationHelper.getTranslations(locale.languageCode);

      _initialized = true;
      return true;
    }
  }

  void _loadFallbackEnglish() {
    _localizedStrings = {
      "app_title": "PADELTID",
      "home": "Home",
      "settings": "Settings",
      "account": "Account",
      "language": "Language",
      "select_language": "Select Language",
      "english": "English",
      "danish": "Danish",
      "welcome_sign_in": "Welcome to PadelTid, please sign in!",
      "welcome_sign_up": "Welcome to PadelTid, please sign up!",
      "terms_agreement":
          "By signing in, you agree to our terms and conditions.",
      "recommended": "Recommended",
      "all_timeslots": "All timeslots",
      "select_clubs": "Select clubs to see available time slots",
      "no_data": "No data",
      "error_prefix": "Error:"
    };
    print('Using fallback English translations');
  }

  void _loadFallbackDanish() {
    _localizedStrings = {
      "app_title": "PADELTID",
      "home": "Hjem",
      "settings": "Indstillinger",
      "account": "Konto",
      "language": "Sprog",
      "select_language": "Vælg sprog",
      "english": "Engelsk",
      "danish": "Dansk",
      "welcome_sign_in": "Velkommen til PadelTid, log venligst ind!",
      "welcome_sign_up": "Velkommen til PadelTid, opret venligst en konto!",
      "terms_agreement":
          "Ved at logge ind accepterer du vores vilkår og betingelser.",
      "recommended": "Anbefalet",
      "all_timeslots": "Alle tidspunkter",
      "select_clubs": "Vælg klubber for at se tilgængelige tider",
      "no_data": "Ingen data",
      "error_prefix": "Fejl:"
    };
    print('Using fallback Danish translations');
  }

  String translate(String key) {
    // First try our loaded JSON translations
    if (_initialized && _localizedStrings.containsKey(key)) {
      return _localizedStrings[key]!;
    }

    // Fall back to TranslationHelper if key not found or not initialized
    return TranslationHelper.translate(key, locale.languageCode);
  }

  Future<void> forceReload() async {
    _initialized = false;
    _localizedStrings.clear();
    await load();
  }

  int get translationCount {
    return _localizedStrings.length;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'da'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
