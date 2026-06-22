import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/sign_in_screen.dart';
import 'package:rakni_v2/features/auth/create_account_step2_screen.dart';
import 'package:rakni_v2/features/auth/create_account_step3_screen.dart';
import 'package:rakni_v2/features/main/main_shell.dart';
import 'package:rakni_v2/features/splash/splash_screen.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/models/blacklist_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/features/blacklist/blacklist_warning_screen.dart';

/// Routes based on Firebase auth state + Firestore profile completeness + API Blacklist check.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Key _blacklistKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Auth Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(navigate: false);
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const SignInScreen();
        }

        // If email is not verified, force them to Step 2 screen.
        if (!user.emailVerified) {
          return CreateAccountStep2Screen(
            fullName: user.displayName ?? '',
            email: user.email ?? '',
            password: '',
          );
        }

        // Check Firestore for a complete profile.
        // Firestore automatically handles offline persistence and automatic retries in the background.
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnap) {
            if (firestoreSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen(navigate: false);
            }

            if (firestoreSnap.hasError) {
              debugPrint('AuthGate: Firestore stream error: ${firestoreSnap.error}');
              // Stay in loading state while Firestore retries in the background.
              return const SplashScreen(navigate: false);
            }

            final data = firestoreSnap.data;
            final bool profileComplete =
                data != null && data.exists && (data.data() as Map<String, dynamic>?)?['profileComplete'] == true;

            if (profileComplete) {
              return StreamBuilder<List<VehicleModel>>(
                stream: FirestoreService.instance.streamVehicles(user.uid),
                builder: (context, vehiclesSnap) {
                  if (vehiclesSnap.connectionState == ConnectionState.waiting) {
                    return const SplashScreen(navigate: false);
                  }

                  final vehicles = vehiclesSnap.data ?? [];
                  if (vehicles.isEmpty) {
                    // No vehicles registered yet, proceed to MainShell
                    return const MainShell();
                  }

                  final plates = vehicles.map((v) => v.plateNumber).toList();
                  return FutureBuilder<BlacklistStatus?>(
                    key: _blacklistKey,
                    future: ParkingHardwareApiService.instance.checkBlacklist(plates),
                    builder: (context, blacklistSnap) {
                      if (blacklistSnap.connectionState == ConnectionState.waiting) {
                        return const SplashScreen(navigate: false);
                      }

                      final blacklist = blacklistSnap.data;
                      if (blacklist != null && blacklist.isActive) {
                        return BlacklistWarningScreen(
                          reason: blacklist.reason,
                          plateNumbers: plates,
                          onRecheck: () {
                            setState(() {
                              _blacklistKey = UniqueKey();
                            });
                          },
                        );
                      }

                      return const MainShell();
                    },
                  );
                },
              );
            }

            // If profile is not complete, show Step 3.
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
