import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    print('Loading translations for locale: ${locale.languageCode}');

    try {
      // Try loading from assets/l10n/
      String jsonString = await rootBundle
          .loadString('assets/l10n/app_${locale.languageCode}.json');
      _loadFromString(jsonString);
      _initialized = true;
      return true;
    } catch (e1) {
      print('Error loading from assets/l10n/: $e1');

      // Fallback attempt: try loading from just assets/
      try {
        String jsonString = await rootBundle
            .loadString('assets/app_${locale.languageCode}.json');
        _loadFromString(jsonString);
        _initialized = true;
        return true;
      } catch (e2) {
        print('Error loading from assets/: $e2');
        print(
            '⚠️ Failed to load translations for ${locale.languageCode}. Using hardcoded fallbacks.');

        // Load hardcoded fallbacks
        if (locale.languageCode == 'da') {
          _loadFallbackDanish();
        } else {
          _loadFallbackEnglish();
        }

        _initialized = true;
        return false;
      }
    }
  }

  void _loadFromString(String jsonString) {
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    print(
        'Translations loaded successfully (${_localizedStrings.length} entries)');
    print('Sample entries:');
    int count = 0;
    _localizedStrings.forEach((key, value) {
      if (count < 5) {
        print('  $key: $value');
        count++;
      }
    });
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
    if (!_initialized) {
      print('⚠️ Attempting to translate "$key" before initialization');
      load(); // Try to load asynchronously, won't help for this call but might help later ones
      return key;
    }

    final value = _localizedStrings[key];
    if (value == null) {
      print('⚠️ Translation missing for key: "$key"');
      return key;
    }
    return value;
  }

  Future<void> forceReload() async {
    print('Force reloading translations for ${locale.languageCode}...');
    _initialized = false;
    _localizedStrings.clear();
    await load();
    print('Translations after reload: ${_localizedStrings.length} entries');
    // Debug: Print all keys to verify they're loaded
    print('All loaded keys: ${_localizedStrings.keys.toList()}');
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
