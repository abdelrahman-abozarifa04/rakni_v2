import 'package:flutter/material.dart';

import '../services/theme_service.dart';

/// All color getters delegate to ThemeService.instance.isDark so every widget
/// using AppColors.X is theme-reactive without any extra wiring.
/// Field NAMES are unchanged — zero call-site impact.
class AppColors {
  AppColors._();

  // ── Private dark palette ──────────────────────────────────────────────────
  static const Color _darkPrimary = Color(0xFF2A2A2B);
  static const Color _darkBackground = Color(0xFF2A2A2B);
  static const Color _darkSurface = Color(0xFF3A3B3B);
  static const Color _darkFieldStroke = Color(0xFF3D434C);
  static const Color _darkFieldColor = Color(0xFF3A3B3B);
  static const Color _darkHintColor = Color(0xFF6A7282);
  static const Color _darkTextSecondary = Color(0xFF99A1AF);
  static const Color _darkNavBarBackground = Color(0xFF1E1E1F);

  // ── Private light palette ─────────────────────────────────────────────────
  static const Color _lightPrimary = Color(0xFFF5F5F5);
  static const Color _lightBackground = Color(0xFFF2F3F5);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightFieldStroke = Color(0xFFD1D5DB);
  static const Color _lightFieldColor = Color(0xFFFFFFFF);
  static const Color _lightHintColor = Color(0xFF9CA3AF);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightNavBarBackground = Color(0xFFFFFFFF);

  static bool get _d => ThemeService.instance.isDark;

  // ── Semantic getters (read isDark on every build) ─────────────────────────

  /// App-wide primary color (dark gray in dark mode, near-white in light mode)
  static Color get primary => _d ? _darkPrimary : _lightPrimary;

  /// Scaffold / page background
  static Color get background => _d ? _darkBackground : _lightBackground;

  /// Card / modal surface
  static Color get surface => _d ? _darkSurface : _lightSurface;

  /// Input field border stroke
  static Color get fieldStroke => _d ? _darkFieldStroke : _lightFieldStroke;

  /// Input field fill color
  static Color get fieldColor => _d ? _darkFieldColor : _lightFieldColor;

  /// Placeholder / hint text
  static Color get hintColor => _d ? _darkHintColor : _lightHintColor;

  /// Secondary text (subdued)
  static Color get textSecondary =>
      _d ? _darkTextSecondary : _lightTextSecondary;

  /// Bottom nav bar background
  static Color get navBarBackground =>
      _d ? _darkNavBarBackground : _lightNavBarBackground;

  /// Subtle shadow / overlay (replaces Colors.black12)
  static Color get shadow => Colors.black.withValues(alpha: 0.12);

  // ── Theme-invariant constants ─────────────────────────────────────────────

  /// Theme-invariant neon lime constant
  static const Color secondary = Color(0xFFBDE500);

  /// Theme-reactive accent color (returns secondary in dark mode, and a darker, more readable lime green in light mode)
  static Color get accent => _d ? secondary : const Color(0xFF8CA800);

  /// Error red
  static const Color error = Color(0xFFEF4444);

  /// Dynamic white (white in dark mode, dark gray/charcoal in light mode)
  static Color get white => _d ? Colors.white : const Color(0xFF2A2A2B);

  /// Pure black (use for text on `secondary` background in any theme)
  static const Color black = Colors.black;
}
