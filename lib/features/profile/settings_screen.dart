import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rakni_v2/core/localization/app_strings.dart';
import 'package:rakni_v2/core/localization/locale_service.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/legal/privacy_policy_screen.dart';
import 'package:rakni_v2/features/legal/terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _parkingReminders = true;
  bool _promotions = false;
  bool _locationServices = true;
  // _darkMode removed — ThemeService is the source of truth
  String _language = 'English'; // display label, synced from LocaleService
  String _currency = 'EGP';

  static const String _keyPush = 'setting_push_notifications';
  static const String _keyEmail = 'setting_email_notifications';
  static const String _keyReminders = 'setting_parking_reminders';
  static const String _keyPromo = 'setting_promotions';
  static const String _keyLocation = 'setting_location_services';
  static const String _keyCurrency = 'setting_currency';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool(_keyPush) ?? true;
      _emailNotifications = prefs.getBool(_keyEmail) ?? false;
      _parkingReminders = prefs.getBool(_keyReminders) ?? true;
      _promotions = prefs.getBool(_keyPromo) ?? false;
      _locationServices = prefs.getBool(_keyLocation) ?? true;
      // Sync language display label from LocaleService
      _language = LocaleService.instance.isArabic ? 'العربية' : 'English';
      _currency = prefs.getString(_keyCurrency) ?? 'EGP';
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeService.instance,
        LocaleService.instance,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppStrings.settings,
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
              // Notifications Section
              _sectionTitle(AppStrings.notifications),
              const SizedBox(height: 12),
              _buildToggle(
                icon: Icons.notifications_outlined,
                title: AppStrings.pushNotifications,
                subtitle: AppStrings.pushNotificationsSubtitle,
                value: _pushNotifications,
                onChanged: (v) {
                  setState(() => _pushNotifications = v);
                  _saveBool(_keyPush, v);
                },
              ),
              const SizedBox(height: 8),
              _buildToggle(
                icon: Icons.email_outlined,
                title: AppStrings.emailNotifications,
                subtitle: AppStrings.emailNotificationsSubtitle,
                value: _emailNotifications,
                onChanged: (v) {
                  setState(() => _emailNotifications = v);
                  _saveBool(_keyEmail, v);
                },
              ),
              const SizedBox(height: 8),
              _buildToggle(
                icon: Icons.alarm_outlined,
                title: AppStrings.parkingReminders,
                subtitle: AppStrings.parkingRemindersSubtitle,
                value: _parkingReminders,
                onChanged: (v) {
                  setState(() => _parkingReminders = v);
                  _saveBool(_keyReminders, v);
                },
              ),
              const SizedBox(height: 8),
              _buildToggle(
                icon: Icons.local_offer_outlined,
                title: AppStrings.promotions,
                subtitle: AppStrings.promotionsSubtitle,
                value: _promotions,
                onChanged: (v) {
                  setState(() => _promotions = v);
                  _saveBool(_keyPromo, v);
                },
              ),
              const SizedBox(height: 24),

              // Privacy & Security Section
              _sectionTitle(AppStrings.privacySecurity),
              const SizedBox(height: 12),
              _buildToggle(
                icon: Icons.location_on_outlined,
                title: AppStrings.locationServices,
                subtitle: AppStrings.locationServicesSubtitle,
                value: _locationServices,
                onChanged: (v) {
                  setState(() => _locationServices = v);
                  _saveBool(_keyLocation, v);
                },
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                icon: Icons.lock_outline,
                title: AppStrings.changePassword,
                onTap: () => _showChangePasswordDialog(),
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                icon: Icons.security_outlined,
                title: AppStrings.twoFactorAuth,
                onTap: () => _showComingSoonDialog(AppStrings.twoFactorAuth),
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                icon: Icons.history_outlined,
                title: AppStrings.loginActivity,
                onTap: () => _showComingSoonDialog(AppStrings.loginActivity),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              _sectionTitle(AppStrings.appearance),
              const SizedBox(height: 12),
              _buildToggle(
                icon: Icons.dark_mode_outlined,
                title: AppStrings.darkMode,
                subtitle: AppStrings.darkModeSubtitle,
                value: ThemeService.instance.isDark,
                onChanged: (v) {
                  ThemeService.instance.setDark(v);
                },
              ),
              const SizedBox(height: 24),

              // Regional Section
              _sectionTitle(AppStrings.regional),
              const SizedBox(height: 12),
              _buildDropdown(
                icon: Icons.language_outlined,
                title: AppStrings.language,
                value: _language,
                items: const ['English', 'العربية'],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _language = v);
                  LocaleService.instance.setLocale(
                    v == 'العربية' ? AppLocale.ar : AppLocale.en,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                icon: Icons.attach_money_outlined,
                title: AppStrings.currency,
                value: _currency,
                items: const ['EGP', 'USD', 'EUR', 'SAR', 'AED'],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _currency = v);
                  _saveString(_keyCurrency, v);
                },
              ),
              const SizedBox(height: 24),

              // Legal
              _sectionTitle(AppStrings.legal),
              const SizedBox(height: 12),
              _buildNavItem(
                icon: Icons.privacy_tip_outlined,
                title: AppStrings.privacyPolicy,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                icon: Icons.description_outlined,
                title: AppStrings.termsOfService,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Danger Zone
              _sectionTitle(AppStrings.account),
              const SizedBox(height: 12),
              _buildNavItem(
                icon: Icons.delete_outline,
                title: AppStrings.deleteAccount,
                textColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => _showDeleteAccountDialog(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.secondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.secondary,
            activeTrackColor: AppColors.secondary.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.background,
            inactiveThumbColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final effectiveTextColor = textColor ?? AppColors.white;
    final effectiveIconColor = iconColor ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.surface,
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
              icon: Icon(
                Icons.expand_more,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.changePassword,
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(currentCtrl, AppStrings.currentPassword, obscure: true),
            const SizedBox(height: 12),
            _dialogField(newCtrl, AppStrings.newPasswordLabel, obscure: true),
            const SizedBox(height: 12),
            _dialogField(confirmCtrl, AppStrings.confirmNewPassword, obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newPassword = newCtrl.text.trim();
              final confirmPassword = confirmCtrl.text.trim();
              if (newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password cannot be empty'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(ctx); // pop the dialog

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
              );

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(newPassword);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.passwordChanged),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No user is currently signed in.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().contains('requires-recent-login')
                            ? 'Please log out and log back in, then try again.'
                            : 'Error updating password: $e',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(AppStrings.update),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.secondary),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$featureName is currently under development and will be available in a future update.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.deleteAccount,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppStrings.deleteAccountContent,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              );
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final uid = user.uid;
                  // 1. Delete user document from Firestore
                  await FirebaseFirestore.instance.collection('users').doc(uid).delete();

                  // 2. Delete user account from Firebase Authentication
                  await user.delete();

                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully.'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  debugPrint('Error deleting account: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().contains('requires-recent-login')
                            ? 'Please log out and log back in to delete your account for security reasons.'
                            : 'Failed to delete account: $e',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(AppStrings.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
