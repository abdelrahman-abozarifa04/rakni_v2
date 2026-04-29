import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/create_account_step2_screen.dart';

class CreateAccountStep1Screen extends StatefulWidget {
  const CreateAccountStep1Screen({super.key});

  @override
  State<CreateAccountStep1Screen> createState() => _CreateAccountStep1ScreenState();
}

class _CreateAccountStep1ScreenState extends State<CreateAccountStep1Screen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  void _goToStep2() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountStep2Screen(
          fullName: name,
          email: email,
          password: password,
        ),
      ),
    );
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
          label: const Text(
            'Back',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w400),
          ),
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
                    const Text('Create Account', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    const Text('Step 1 of 3', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.fieldStroke, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.fieldStroke, borderRadius: BorderRadius.circular(2)))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('Full Name', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _nameController, hintText: 'Enter your full name', prefixIcon: const Icon(Icons.person_outline, color: AppColors.hintColor, size: 20)),
                    const SizedBox(height: 20),
                    const Text('Email', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _emailController, hintText: 'Enter your email', keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.mail_outline, color: AppColors.hintColor, size: 20)),
                    const SizedBox(height: 20),
                    const Text('Create Password', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Create a password',
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.hintColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.hintColor, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Confirm Password', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.hintColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.hintColor, size: 20),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.fieldColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.fieldStroke)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text('A verification code will be sent to your email.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _goToStep2,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, minimumSize: const Size(double.infinity, 56)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, TextInputType keyboardType = TextInputType.text, Widget? prefixIcon, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.hintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.fieldColor,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 1)),
      ),
    );
  }
}
