import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isAmharic => _locale.languageCode == 'am';

  LanguageProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    await setLocale(
      _locale.languageCode == 'en'
          ? const Locale('am')
          : const Locale('en'),
    );
  }
}