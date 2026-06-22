import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/features/profile/help_support_screen.dart';

class BlacklistWarningScreen extends StatefulWidget {
  final String reason;
  final List<String> plateNumbers;
  final VoidCallback onRecheck;

  const BlacklistWarningScreen({
    super.key,
    required this.reason,
    required this.plateNumbers,
    required this.onRecheck,
  });

  @override
  State<BlacklistWarningScreen> createState() => _BlacklistWarningScreenState();
}

class _BlacklistWarningScreenState extends State<BlacklistWarningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _autoCheckTimer;
  bool _isRechecking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _startAutoCheck();
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isRechecking) return;
      try {
        final status = await ParkingHardwareApiService.instance.checkBlacklist(widget.plateNumbers);
        if (status == null || !status.isActive) {
          _autoCheckTimer?.cancel();
          if (mounted) {
            widget.onRecheck();
          }
        }
      } catch (e) {
        debugPrint('Periodic blacklist check failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRecheck() async {
    if (_isRechecking) return;
    setState(() => _isRechecking = true);
    try {
      final status = await ParkingHardwareApiService.instance.checkBlacklist(widget.plateNumbers);
      if (status == null || !status.isActive) {
        _autoCheckTimer?.cancel();
        if (mounted) {
          widget.onRecheck();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.reason.isNotEmpty
                    ? 'Still restricted: ${status.reason}'
                    : 'Your account is still restricted.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to check status. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRechecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Warning Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withAlpha(76),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Restriction Title
              const Text(
                'Access Restricted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle/Explanation
              Text(
                'Your account has been restricted from using Rakni services because one of your vehicles is blacklisted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Reason Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.fieldStroke,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REASON FOR RESTRICTION',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.reason.isNotEmpty ? widget.reason : 'No reason specified by administrator.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isRechecking ? null : _handleRecheck,
                  icon: _isRechecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Recheck Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppColors.fieldStroke, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withAlpha(180),
                    side: BorderSide(color: AppColors.fieldStroke.withAlpha(120), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                    try {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context); // Dismiss loading
                      debugPrint('Sign out error: $e');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
