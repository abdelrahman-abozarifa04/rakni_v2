import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/otp_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/new_password_screen.dart';
import 'package:rakni_v2/features/auth/create_account_step3_screen.dart';

// NOTE: This screen and the OTP flow appear to be currently unreachable dead code,
// as the app uses the email link authentication flow (AuthService.sendPasswordResetEmail / sendEmailVerification).
class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final OtpType type;
  final String? fullName;
  final String? uid;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    this.type = OtpType.passwordReset,
    this.fullName,
    this.uid,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showSnackBar('Please enter the full 6-digit code.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final result = await OtpService.instance.verifyOTP(
        email: widget.email,
        code: otp,
        type: widget.type,
      );

      if (!mounted) return;

      if (result.success) {
        if (widget.type == OtpType.passwordReset) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewPasswordScreen(email: widget.email),
            ),
          );
        } else {
          // SignUp verification flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAccountStep3Screen(
                fullName: widget.fullName!,
                email: widget.email,
                uid: widget.uid!,
              ),
            ),
          );
        }
      } else {
        _showSnackBar(result.error ?? 'Invalid or expired code. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      if (widget.type == OtpType.passwordReset) {
        await OtpService.instance.sendPasswordResetOTP(email: widget.email);
      } else {
        await OtpService.instance.sendVerificationOTP(
          email: widget.email,
          uid: widget.uid!,
        );
      }
      _showSnackBar('Code resent to ${widget.email}', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          onPressed: (_isVerifying || _isResending)
              ? null
              : () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back,
              color: AppColors.textSecondary, size: 20),
          label: Text('Back',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400)),
          style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 16),
              alignment: Alignment.centerLeft),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32),
              Text('Verification Code',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(
                        text: 'Enter the 6-digit reset code sent to '),
                    TextSpan(
                        text: widget.email,
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(height: 48),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline,
                      color: AppColors.secondary, size: 32),
                ),
              ),
              SizedBox(height: 40),
              // 6-digit OTP row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      enabled: !_isVerifying,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.fieldColor,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.fieldStroke, width: 1)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.fieldStroke, width: 1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.secondary, width: 1)),
                      ),
                      onChanged: (v) => _onOtpChanged(v, i),
                    ),
                  );
                }),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isVerifying
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.black))
                    : Text('Verify',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive it? ",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: (_isVerifying || _isResending) ? null : _resend,
                    child: _isResending
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.secondary))
                        : Text('Resend Code',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
