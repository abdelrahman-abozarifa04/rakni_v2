import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:rakni_v2/firebase_options.dart';

import 'core/services/auth_gate.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();


  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {

  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakni',
      debugShowCheckedModeBanner: false,

    
      theme: ThemeData(
        useMaterial3: true, 
        fontFamily: 'SF Pro Display',


        scaffoldBackgroundColor: const Color(0xFF0E0E12),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFFD0FD3E,
          ), 
          brightness: Brightness.dark,
        ),
      ),

      home: AuthGate(),
    );
  }
}
