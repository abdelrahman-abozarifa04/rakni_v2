import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/auth_gate.dart';
import 'package:rakni_v2/features/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool navigate;
  const SplashScreen({super.key, this.navigate = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _outerScale;
  late Animation<double> _middleScale;
  late Animation<double> _innerScale;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize the Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600), // Adjust speed here
    );

    // 2. Define staggered animations using Intervals
    _outerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _middleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _innerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // The logo uses an elastic curve for a playful, premium pop
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start the animation
    _controller.forward();
    if (widget.navigate) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleNavigation();
        }
      });
    }
  }

  Future<void> _handleNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => onboardingCompleted ? const AuthGate() : const OnboardingScreen(),
        ),
      );
    } catch (e) {
      debugPrint('SplashScreen navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    }
  }

  @override
  void dispose() {
    // Always dispose of controllers to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/images/Rakni_logo_dark.svg'
        : 'assets/images/rakni_logo_white.svg';

    return Scaffold(
      backgroundColor: AppColors.background,
      // Using a Stack instead of deeply nested containers is better for performance and readability
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring
            ScaleTransition(
              scale: _outerScale,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.fieldStroke.withValues(alpha: 0.5), // Subtle opacity for modern layering
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Middle Ring
            ScaleTransition(
              scale: _middleScale,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Inner Ring
            ScaleTransition(
              scale: _innerScale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  // Added a soft shadow for modern depth (Neumorphic touch)
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            
            // Logo
            ScaleTransition(
              scale: _logoScale,
              child: SvgPicture.asset(
                logoAsset,
                width: 90, 
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}