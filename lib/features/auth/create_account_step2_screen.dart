import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/otp_service.dart';
import 'package:rakni_v2/features/auth/create_account_step3_screen.dart';

class CreateAccountStep2Screen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const CreateAccountStep2Screen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<CreateAccountStep2Screen> createState() => _CreateAccountStep2ScreenState();
}

class _CreateAccountStep2ScreenState extends State<CreateAccountStep2Screen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _timerSeconds = 60;
  Timer? _timer;
  bool _isResending = false;
  bool _isVerifying = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Pre-create the user in Firebase Auth so we have a UID to link the OTP to
    // and to prepare for the final registration step.
    _preCreateUser();
  }

  Future<void> _preCreateUser() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      _uid = userCredential.user?.uid;
      // Set display name so it can be recovered by AuthGate if needed
      await userCredential.user?.updateDisplayName(widget.fullName);
      
      // Trigger the OTP send now that we have a real UID
      _sendOtp();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If user already exists, they might be trying to resume or reset.
        // For simplicity in this demo, we'll just try to sign in.
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
          _uid = cred.user?.uid;
          _sendOtp();
        } catch (_) {
          _showSnackBar('Email is already registered. Please sign in.');
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(e.message ?? 'Failed to initialize account.');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred.');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (_uid == null) return;
    
    setState(() => _isResending = true);
    try {
      await OtpService().sendVerificationOTP(
        email: widget.email,
        uid: _uid!,
      );
    } catch (e) {
      _showSnackBar('Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _resendCode() {
    if (_timerSeconds == 0) {
      _startTimer();
      _sendOtp();
    }
  }

  Future<void> _verifyAndProceed() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showSnackBar('Please enter the full 6-digit code.');
      return;
    }
    if (_uid == null) {
      _showSnackBar('Account not ready. Please wait a moment or go back.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final result = await OtpService().verifyOTP(
        email: widget.email,
        code: otp,
        type: OtpType.verification,
      );

      if (!mounted) return;

      if (!result.success) {
        _showSnackBar(result.error ?? 'Invalid or expired code.');
        return;
      }

      // Success! Proceed to Step 3
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccountStep3Screen(
            uid: _uid!,
            fullName: widget.fullName,
            email: widget.email,
          ),
        ),
        (route) => false, // Clear stack to prevent going back to OTP
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 20),
          label: const Text('Back', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 16), alignment: Alignment.centerLeft),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Text('Verify Email', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    const Text('Step 2 of 3', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.fieldStroke, borderRadius: BorderRadius.circular(2)))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text('We have sent a code to', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(widget.email, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => _buildOtpField(index)),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _timerSeconds > 0 
                                ? 'Resend code in ${_timerSeconds}s'
                                : 'Didn\'t receive the code?',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          if (_timerSeconds == 0)
                            TextButton(
                              onPressed: _isResending ? null : _resendCode,
                              child: _isResending 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                                  : const Text('Resend Code', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: (_isVerifying || _uid == null) ? null : _verifyAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? AppColors.secondary : AppColors.fieldStroke,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (otpComplete) {
             _verifyAndProceed();
          }
        },
      ),
    );
  }

  bool get otpComplete => _controllers.every((c) => c.text.isNotEmpty);
}
