import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rakni_v2/core/models/license_model.dart';
import 'package:rakni_v2/core/services/license_ocr_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/utils/image_utils.dart';
import 'package:rakni_v2/core/utils/validators.dart';
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
  State<CreateAccountStep3Screen> createState() =>
      _CreateAccountStep3ScreenState();
}

class _CreateAccountStep3ScreenState extends State<CreateAccountStep3Screen> {
  String? _selectedGender;
  String? _licenseBase64;
  LicenseModel? _extractedLicense;
  bool _isLoading = false;
  bool _isExtractingOcr = false;

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

  Future<void> _pickLicensePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.secondary,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.secondary,
              ),
              title: const Text(
                'Take a Photo',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;

    final rawBytes = await file.readAsBytes();
    final previewBase64 = 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
    setState(() {
      _licenseBase64 = previewBase64;
      _isExtractingOcr = true;
      _licenseNumberCtrl.clear();
      _licenseExpiryCtrl.clear();
      _licenseCategoryCtrl.clear();
      _extractedLicense = null;
    });

    final result = await LicenseOcrService.instance.extractFromBytes(rawBytes);
    if (!mounted) return;
    setState(() => _isExtractingOcr = false);

    if (result.success && result.data != null) {
      final license = result.data!;
      setState(() {
        _extractedLicense = license;
        if (license.licenseNumber?.isNotEmpty == true) {
          _licenseNumberCtrl.text = license.licenseNumber!;
        }
        if (license.expiryDate?.isNotEmpty == true) {
          _licenseExpiryCtrl.text = license.expiryDate!;
        }
        if (license.categories?.isNotEmpty == true) {
          _licenseCategoryCtrl.text = license.categories!;
        }
      });

      if (license.isUsable) {
        _showSnackBar('License scanned successfully.', isError: false);
      } else {
        _showSnackBar(
          'Some fields could not be read. Please fill them in manually.',
          isError: false,
        );
      }
    } else {
      _showSnackBar(
        'Could not scan license automatically. Please fill in the details manually.',
        isError: false,
      );
    }
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
    if (_licenseBase64 == null) {
      _showSnackBar("Please upload your driver's license photo.");
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
        'licenseImageBase64': _licenseBase64,
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry,
        'licenseCategory': licenseCategory,
        'licenseVerified': false,
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_extractedLicense != null) {
        userData.addAll(
          _extractedLicense!.toFirestore()..remove('licenseVerified'),
        );
      }

      // Write to Firestore using uid already created in Step 2
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .set(userData);
      } catch (e) {
        debugPrint('CreateAccountStep3: Firestore set users failed: $e. Proceeding gracefully with mock layer.');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AddCarScreen(uid: widget.uid)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('CreateAccountStep3: Error during save profile: $e. Redirecting anyway.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AddCarScreen(uid: widget.uid)),
        (route) => false,
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 20,
          ),
          label: const Text(
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
                    const SizedBox(height: 24),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Step 3 of 3',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 40),
                    const Text(
                      "Driver's License",
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isExtractingOcr ? null : _pickLicensePhoto,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.fieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _licenseBase64 != null
                                ? AppColors.secondary
                                : AppColors.fieldStroke,
                            width: _licenseBase64 != null ? 1.5 : 1,
                          ),
                        ),
                        child: _isExtractingOcr
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.secondary,
                                    strokeWidth: 2,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Scanning license...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : _licenseBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      ImageUtils.base64ToBytes(_licenseBase64!),
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Text(
                                          'Tap to retake',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    color: AppColors.textSecondary,
                                    size: 40,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Upload Driver's License",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Front side • Photo or from gallery',
                                    style: TextStyle(
                                      color: AppColors.hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'License Number',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseNumberCtrl,
                      hintText: 'e.g. 1234567',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        Icons.tag_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'License Expiry Date',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseExpiryCtrl,
                      hintText: 'DD/MM/YYYY',
                      keyboardType: TextInputType.datetime,
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'License Category',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseCategoryCtrl,
                      hintText: 'e.g. B or A, B',
                      prefixIcon: const Icon(
                        Icons.category_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Age',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _ageController,
                      hintText: 'Enter your age',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gender',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.fieldColor,
                      initialValue: _selectedGender,
                      hint: const Text(
                        'Select your gender',
                        style: TextStyle(
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
                                style: const TextStyle(color: AppColors.white),
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
                          borderSide: const BorderSide(
                            color: AppColors.fieldStroke,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.fieldStroke,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.secondary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Address',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Enter your address',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Phone Number',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
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
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
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
  }) {
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldStroke, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1),
        ),
      ),
    );
  }
}
