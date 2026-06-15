import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakni_v2/firebase_options.dart';

import 'core/services/auth_gate.dart';

/// Global [FirebaseAnalytics] instance — used across the app to log events.
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  // Ensure plugin bindings are ready before any Firebase calls.
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded<Future<void>>(
    () async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // ── Crashlytics ──────────────────────────────────────────────────────
        // Catch Flutter framework errors (widget build failures, etc.)
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Disable Crashlytics in debug mode so it doesn't pollute the console.
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );

      runApp(const MyApp());
    },
    // Catch asynchronous Dart errors that escape the widget tree.
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakni',
      debugShowCheckedModeBanner: false,

      // Wire Analytics navigator observer so screen views are tracked.
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',

        scaffoldBackgroundColor: const Color(0xFF0E0E12),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0FD3E),
          brightness: Brightness.dark,
        ),
      ),

      home: AuthGate(),
    );
  }
}
