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
import 'package:rakni_v2/core/services/notification_service.dart';

import 'features/splash/splash_screen.dart';
import 'package:rakni_v2/core/services/auth_gate.dart';

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
          if (!kIsWeb) {
            try {
              FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
            } catch (_) {}
          }
          FlutterError.dumpErrorToConsole(errorDetails);
        };

        if (!kIsWeb) {
          // Disable Crashlytics in debug mode so it doesn't pollute the console.
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(!kDebugMode);
        }
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      // ── Theme & Locale ───────────────────────────────────────────────────
      // ThemeService.init() also calls _applySystemOverlay(), so the old
      // hardcoded SystemChrome.setSystemUIOverlayStyle is no longer needed.
      await ThemeService.instance.init();
      await LocaleService.instance.init();
      await LocalNotificationService.init();

      runApp(const MyApp());
    },
    // Catch asynchronous Dart errors that escape the widget tree.
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
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

          builder: (context, child) {
            final appChild = ThemeRebuilder(child: child!);
            return kIsWeb ? _WebShell(child: appChild) : appChild;
          },

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

          home: kIsWeb ? const AuthGate() : const SplashScreen(navigate: true),
        );
      },
    );
  }
}

/// A widget that listens to ThemeService changes and recursively marks
/// all active elements below it as needing a rebuild. This is necessary because
/// the app uses a static AppColors utility class to resolve colors instead of
/// Theme.of(context), meaning Flutter doesn't automatically track color dependencies
/// to rebuild widgets when the theme changes.
class ThemeRebuilder extends StatefulWidget {
  final Widget child;
  const ThemeRebuilder({super.key, required this.child});

  @override
  State<ThemeRebuilder> createState() => _ThemeRebuilderState();
}

class _ThemeRebuilderState extends State<ThemeRebuilder> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
      // Recursively mark all descendant elements as needing rebuild to support static AppColors
      void rebuildElement(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuildElement);
      }
      (context as Element).visitChildren(rebuildElement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A shell wrapper for Flutter Web to center the mobile app within a 430px boundary.
class _WebShell extends StatelessWidget {
  final Widget child;
  const _WebShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    // AppColors.background darkened slightly for outside app frame
    final shellBg = isDark ? const Color(0xFF1E1E1F) : const Color(0xFFE2E3E5);

    return Scaffold(
      backgroundColor: shellBg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
