import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rakni_v2/core/localization/locale_service.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/firebase_options.dart';

import 'core/services/auth_gate.dart';

/// Global [FirebaseAnalytics] instance — used across the app to log events.
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      // Ensure plugin bindings are ready before any Firebase calls.
      // Must be inside runZonedGuarded so the binding zone matches runApp zone.
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // ── Crashlytics ──────────────────────────────────────────────────────
        // Catch Flutter framework errors (widget build failures, etc.)
        FlutterError.onError = (errorDetails) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          } catch (_) {}
          FlutterError.dumpErrorToConsole(errorDetails);
        };

        // Disable Crashlytics in debug mode so it doesn't pollute the console.
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      // ── Theme & Locale ───────────────────────────────────────────────────
      // ThemeService.init() also calls _applySystemOverlay(), so the old
      // hardcoded SystemChrome.setSystemUIOverlayStyle is no longer needed.
      await ThemeService.instance.init();
      await LocaleService.instance.init();

      runApp(const MyApp());
    },
    // Catch asynchronous Dart errors that escape the widget tree.
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder re-runs build whenever theme OR locale changes.
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeService.instance,
        LocaleService.instance,
      ]),
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark;

        return MaterialApp(
          title: 'Rakni',
          debugShowCheckedModeBanner: false,

          // ── Localization ─────────────────────────────────────────────────
          locale: LocaleService.instance.flutterLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar', 'EG'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Analytics ────────────────────────────────────────────────────
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: analytics),
          ],

          // ── Theme ────────────────────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'SF Pro Display',
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.secondary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),

          home: AuthGate(),
        );
      },
    );
  }
}
