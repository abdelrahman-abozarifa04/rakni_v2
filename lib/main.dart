import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضفنا دي عشان نتحكم في ألوان الـ Status Bar
import 'package:rakni_v2/core/services/firebase_options.dart';
import 'package:rakni_v2/features/splash/splash_screen.dart';

import 'core/services/auth_gate.dart';

Future<void> main() async {
  print('--- App Starting ---');
  // 1. التأكد من تهيئة أدوات فلاتر
  WidgetsFlutterBinding.ensureInitialized();
  print('--- WidgetsFlutterBinding Initialized ---');

  // 2. تهيئة Firebase باستخدام الإعدادات اللي ولدتها الـ CLI
  try {
    print('--- Initializing Firebase ---');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('--- Firebase Initialized ---');
  } catch (e) {
    print('--- Firebase Initialization Error: $e ---');
  }

  // 3. (اختياري) جعل الـ Status Bar شفاف ليناسب تصميم الـ Dark Mode بتاعك
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  print('--- Running App ---');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakni',
      debugShowCheckedModeBanner: false,
      
      // إعدادات الثيم الأساسية لمشروع Rakni
      theme: ThemeData(
        useMaterial3: true, // تفعيل Material 3 لأحدث أشكال الـ Widgets
        fontFamily: 'SF Pro Display',
        
        // توحيد لون الخلفية في التطبيق كله
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
        
        // إعدادات افتراضية للـ ColorScheme عشان تتوافق مع Firebase UI لاحقاً
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0FD3E), // لون الـ Secondary (الليموني) بتاعك
          brightness: Brightness.dark,
        ),
      ),
      
      home:  AuthGate(),
    );
  }
}