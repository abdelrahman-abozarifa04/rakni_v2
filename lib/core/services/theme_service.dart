import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton owning the app's light/dark state. Same pattern as
/// FavoritesService: private constructor + static instance + SharedPreferences.
/// AppColors reads this on every build, so any widget using AppColors.X is
/// theme-reactive for free — see main.dart for the root listener that makes
/// this propagate app-wide.
class ThemeService extends ChangeNotifier {
  ThemeService._internal();
  static final ThemeService instance = ThemeService._internal();

  static const String _key = 'rakni_theme_mode';

  bool _isDark = true;
  bool get isDark => _isDark;

  /// Call once in main() before runApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    _applySystemOverlay();
    notifyListeners();
  }

  Future<void> toggle() => setDark(!_isDark);

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    _applySystemOverlay();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  void _applySystemOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
