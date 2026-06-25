import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/utils/validators.dart';
import 'package:rakni_v2/core/utils/input_formatters.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/features/auth/add_car_screen.dart';
import 'package:rakni_v2/features/auth/sign_in_screen.dart';

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
  State<CreateAccountStep3Screen> createState() =>
      _CreateAccountStep3ScreenState();
}

class _CreateAccountStep3ScreenState extends State<CreateAccountStep3Screen> {
  String? _selectedGender;
  bool _isLoading = false;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseNumberCtrl = TextEditingController();
  final TextEditingController _licenseExpiryCtrl = TextEditingController();
  final TextEditingController _licenseCategoryCtrl = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _licenseNumberCtrl.dispose();
    _licenseExpiryCtrl.dispose();
    _licenseCategoryCtrl.dispose();
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
    final age = _ageController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final licenseNumber = _licenseNumberCtrl.text.trim();
    final licenseExpiry = _licenseExpiryCtrl.text.trim();
    final licenseCategory = _licenseCategoryCtrl.text.trim();

    if (age.isEmpty ||
        _selectedGender == null ||
        address.isEmpty ||
        phone.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }
    if (licenseNumber.isEmpty) {
      _showSnackBar('Please enter or confirm your license number.');
      return;
    }
    final licenseNumError = Validators.validateLicenseNumber(licenseNumber);
    if (licenseNumError != null) {
      _showSnackBar(licenseNumError);
      return;
    }
    if (licenseExpiry.isNotEmpty) {
      final expiryError = Validators.validateLicenseExpiry(licenseExpiry);
      if (expiryError != null) {
        _showSnackBar(expiryError);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> userData = {
        'uid': widget.uid,
        'fullName': widget.fullName,
        'email': widget.email,
        'age': age,
        'gender': _selectedGender,
        'address': address,
        'phoneNumber': phone,
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry,
        'licenseCategory': licenseCategory,
        'licenseVerified': false,
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Write to Firestore using uid already created in Step 2.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .set(userData);
      } catch (e) {
        debugPrint('CreateAccountStep3: Firestore set users failed: $e');
        if (!mounted) return;
        _showSnackBar(
          "We couldn't save your profile. Please check your connection and try again.",
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AddCarScreen(uid: widget.uid)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('CreateAccountStep3: Error during save profile: $e');
      _showSnackBar(
        'Something went wrong while saving your profile. Please try again.',
      );
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
          onPressed: _isLoading
              ? null
              : () async {
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                      (route) => false,
                    );
                  }
                },
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 20,
          ),
          label: Text(
            'Back',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
          ),
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
                    SizedBox(height: 24),
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Step 3 of 3',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'License Number',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseNumberCtrl,
                      hintText: 'e.g. 1234567',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.tag_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'License Expiry Date',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseExpiryCtrl,
                      hintText: 'DD/MM/YYYY',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [DateInputFormatter()],
                      prefixIcon: Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'License Category',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseCategoryCtrl,
                      hintText: 'e.g. B or A, B',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Age',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _ageController,
                      hintText: 'Enter your age',
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Gender',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.fieldColor,
                      initialValue: _selectedGender,
                      hint: Text(
                        'Select your gender',
                        style: TextStyle(
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
                                style: TextStyle(color: AppColors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.fieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.fieldStroke,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.fieldStroke,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.secondary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Address',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Enter your address',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Phone Number',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 40),
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
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor: AppColors.secondary.withValues(
                    alpha: 0.6,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : Text(
                        'Create Account',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.hintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.fieldColor,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.fieldStroke, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.fieldStroke, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondary, width: 1),
        ),
      ),
    );
  }
}
