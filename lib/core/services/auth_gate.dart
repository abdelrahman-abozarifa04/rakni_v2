import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/features/auth/sign_in_screen.dart';
import 'package:rakni_v2/features/auth/create_account_step3_screen.dart';
import 'package:rakni_v2/features/main/main_shell.dart';
import 'package:rakni_v2/features/splash/splash_screen.dart';

/// Routes based on Firebase auth state + Firestore profile completeness.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const SignInScreen();
        }

        // Check Firestore for a complete profile
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnap) {
            if (firestoreSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final data = firestoreSnap.data;
            final bool profileComplete =
                data != null && data.exists && (data.get('profileComplete') == true);

            if (profileComplete) {
              return const MainShell();
            }

            // 🛑 CRITICAL FIX: If profile is not complete, show Step 3.
            // Do NOT call signOut() here, as it breaks the registration flow.
            return CreateAccountStep3Screen(
              uid: user.uid,
              fullName: user.displayName ?? '',
              email: user.email ?? '',
            );
          },
        );
      },
    );
  }
}
