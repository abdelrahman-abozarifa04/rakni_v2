import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/add_car_screen.dart';

class CreateAccountStep3Screen extends StatefulWidget {
  final String fullName;
  final String email;
  final String uid;

  const CreateAccountStep3Screen({
    super.key,
    required this.fullName,
    required this.email,
    required this.uid,
  });

  @override
  State<CreateAccountStep3Screen> createState() => _CreateAccountStep3ScreenState();
}

class _CreateAccountStep3ScreenState extends State<CreateAccountStep3Screen> {
  String? _selectedGender;
  bool _isLoading = false;

  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nationalIdController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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

  Future<void> _saveProfile() async {
    final nationalId = _nationalIdController.text.trim();
    final age = _ageController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (nationalId.isEmpty || age.isEmpty || _selectedGender == null || address.isEmpty || phone.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Write to Firestore using uid already created in Step 2
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'uid': widget.uid,
        'fullName': widget.fullName,
        'email': widget.email,
        'nationalId': nationalId,
        'age': age,
        'gender': _selectedGender,
        'address': address,
        'phoneNumber': phone,
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AddCarScreen(uid: widget.uid)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 20),
          label: const Text('Back', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w400)),
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
                    const Text('Personal Information', style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    const Text('Step 3 of 3', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('National ID', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _nationalIdController, hintText: 'Enter your national ID', prefixIcon: const Icon(Icons.credit_card, color: AppColors.textSecondary, size: 20)),
                    const SizedBox(height: 24),
                    const Text('Age', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _ageController, hintText: 'Enter your age', keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    const Text('Gender', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.fieldColor,
                      initialValue: _selectedGender,
                      hint: const Text('Select your gender', style: TextStyle(color: AppColors.hintColor, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      items: ['Male', 'Female', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: AppColors.white)))).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.fieldColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 1)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Address', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _addressController, hintText: 'Enter your address', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20)),
                    const SizedBox(height: 24),
                    const Text('Phone Number', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _phoneController, hintText: 'Enter your phone number', keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, Widget? prefixIcon, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.hintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.fieldColor,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 1)),
      ),
    );
  }
}
