import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/otp_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/sign_in_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  const NewPasswordScreen({super.key, required this.email});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('Please fill in both fields.');
      return;
    }
    if (newPass.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call the backend Cloud Function to update the password via Admin SDK.
      // This works without the user being signed in on the client side.
      await OtpService.instance.resetPassword(
        email: widget.email,
        newPassword: newPass,
      );

      if (!mounted) return;
      _showSnackBar('Password reset successfully!', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('New password', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32),
              Text('New Password', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Create a new password for your account', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              SizedBox(height: 40),
              Text('New Password', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              _buildTextField(controller: _newPasswordController, hintText: 'Enter new password', obscureText: _obscureNewPassword, onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword)),
              SizedBox(height: 20),
              Text('Confirm Password', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              _buildTextField(controller: _confirmPasswordController, hintText: 'Confirm new password', obscureText: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, foregroundColor: AppColors.black,
                  disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                    : Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, required bool obscureText, required VoidCallback onToggle}) {
    return TextField(
      controller: controller, obscureText: obscureText,
      style: TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText, hintStyle: TextStyle(color: AppColors.hintColor, fontSize: 14),
        filled: true, fillColor: AppColors.fieldColor,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.hintColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.hintColor, size: 20),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldStroke, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldStroke, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.secondary, width: 1)),
      ),
    );
  }
}
