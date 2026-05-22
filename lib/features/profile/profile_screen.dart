import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/models/user_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/core/utils/image_utils.dart';
import 'package:rakni_v2/features/profile/personal_details_screen.dart';
import 'package:rakni_v2/features/profile/my_vehicles_screen.dart';
import 'package:rakni_v2/features/profile/payment_methods_screen.dart';
import 'package:rakni_v2/features/profile/settings_screen.dart';
import 'package:rakni_v2/features/profile/help_support_screen.dart';
import 'package:rakni_v2/features/bookings/bookings_screen.dart';
import 'package:rakni_v2/core/services/auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUploading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final model = await FirestoreService.instance.getUserModel(
        currentUser!.uid,
      );
      setState(() {
        _userModel = model;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (currentUser == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final photoUrl = await ImageUtils.xFileToBase64(image);

      await FirestoreService.instance.saveUserData(currentUser!.uid, {
        'photoUrl': photoUrl,
      });

      setState(() {
        if (_userModel != null) {
          _userModel = _userModel!.copyWith(photoUrl: photoUrl);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final rootContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out', style: TextStyle(color: AppColors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await AuthService().signOut();
                if (!mounted) return;
                Navigator.of(rootContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to log out: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _userModel == null
          ? const Center(
              child: Text(
                'User data not found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.surface,
                            backgroundImage: _userModel?.photoUrl != null
                                ? (ImageUtils.isBase64Image(
                                        _userModel!.photoUrl!,
                                      )
                                      ? MemoryImage(
                                          ImageUtils.base64ToBytes(
                                            _userModel!.photoUrl!,
                                          ),
                                        )
                                      : NetworkImage(_userModel!.photoUrl!))
                                : null,
                            child: _userModel?.photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.textSecondary,
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userModel!.fullName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userModel!.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('122', 'Total Parked')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatItem('67', 'Bookings')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatItem('4.9', 'Rating')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile Options
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Personal Details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PersonalDetailsScreen(userModel: _userModel!),
                      ),
                    ).then((_) => _loadUser()),
                  ),
                  _buildProfileOption(
                    icon: Icons.directions_car_outlined,
                    title: 'My Vehicles',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyVehiclesScreen(),
                      ),
                    ),
                  ),
                  _buildProfileOption(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Bookings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingsScreen()),
                    ),
                  ),
                  _buildProfileOption(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen(),
                      ),
                    ),
                  ),
                  _buildProfileOption(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Log Out',
                    textColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: _signOut,
                    showTrailing: false,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = AppColors.white,
    Color iconColor = AppColors.white,
    bool showTrailing = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: showTrailing
            ? const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              )
            : null,
      ),
    );
  }
}
