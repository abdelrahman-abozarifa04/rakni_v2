import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/add_car_screen_2.dart';
import 'package:rakni_v2/features/main/main_shell.dart';

class AddCarScreen extends StatelessWidget {
  final String? uid;

  const AddCarScreen({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 60),
            // ── Logo ──────────────────────────────────────────
            Center(
              child: SvgPicture.asset(
                'assets/images/rakni_logo_white.svg',
                height: 45,
              ),
            ),
            SizedBox(height: 60),

            // ── Header Text ───────────────────────────────────
            Text(
              'Parking made easy..',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your car to start now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // ── Car Graphic & Action Button ────────────────────
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The Car Image (Top View)
                  Image.asset(
                    'assets/images/add_car_photo.png',
                    height: 360,
                    fit: BoxFit.contain,
                  ),

                  // The Lime Green Circular Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCarScreen2(uid: uid),
                        ),
                      );
                    },
                    child: Container(
                      width: 130,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          'ADD YOUR\nCAR TO\nSTART',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── Skip for now ─────────────────────────────────
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                );
              },
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}