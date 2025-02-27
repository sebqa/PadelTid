import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final String _prefsKey = 'language_code';

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_prefsKey);

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    print('Setting locale to: ${locale.languageCode}');
    _locale = locale;

    // Force reload translations for the new locale
    final localizations = AppLocalizations(_locale);
    await localizations.forceReload();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> initialize() async {
    await _loadSavedLocale();

    // Pre-load and force a reload of the AppLocalizations for the current locale
    final localizations = AppLocalizations(_locale);
    await localizations.load();

    // Use the public method instead of accessing private field
    print('Initializing with locale: ${_locale.languageCode}');
    print('Loaded ${localizations.translationCount} translations');

    print('LocaleProvider initialized with locale: ${_locale.languageCode}');
  }
}
