import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { en, ar }


class LocaleService extends ChangeNotifier {
  LocaleService._internal();
  static final LocaleService instance = LocaleService._internal();

  static const String _key = 'rakni_locale';

  AppLocale _locale = AppLocale.en;
  AppLocale get locale => _locale;
  bool get isArabic => _locale == AppLocale.ar;

  Locale get flutterLocale =>
      isArabic ? const Locale('ar', 'EG') : const Locale('en');

  /// Call once in main() before runApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _locale = saved == 'ar' ? AppLocale.ar : AppLocale.en;
    notifyListeners();
  }

  Future<void> setLocale(AppLocale value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value == AppLocale.ar ? 'ar' : 'en');
  }
}
