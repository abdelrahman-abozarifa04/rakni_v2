import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

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
  bool _darkMode = true;
  String _language = 'English';
  String _currency = 'EGP';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notifications Section
          _sectionTitle('Notifications'),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive push alerts on your device',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          const SizedBox(height: 8),
          _buildToggle(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Get booking updates via email',
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          const SizedBox(height: 8),
          _buildToggle(
            icon: Icons.alarm_outlined,
            title: 'Parking Reminders',
            subtitle: 'Alert before parking session ends',
            value: _parkingReminders,
            onChanged: (v) => setState(() => _parkingReminders = v),
          ),
          const SizedBox(height: 8),
          _buildToggle(
            icon: Icons.local_offer_outlined,
            title: 'Promotions & Offers',
            subtitle: 'Receive special deals and discounts',
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          const SizedBox(height: 24),

          // Privacy & Security Section
          _sectionTitle('Privacy & Security'),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'Allow app to access your location',
            value: _locationServices,
            onChanged: (v) => setState(() => _locationServices = v),
          ),
          const SizedBox(height: 8),
          _buildNavItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(),
          ),
          const SizedBox(height: 8),
          _buildNavItem(
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildNavItem(
            icon: Icons.history_outlined,
            title: 'Login Activity',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _sectionTitle('Appearance'),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark theme throughout the app',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const SizedBox(height: 24),

          // Regional Section
          _sectionTitle('Regional'),
          const SizedBox(height: 12),
          _buildDropdown(
            icon: Icons.language_outlined,
            title: 'Language',
            value: _language,
            items: ['English', 'العربية', 'French'],
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            icon: Icons.attach_money_outlined,
            title: 'Currency',
            value: _currency,
            items: ['EGP', 'USD', 'EUR', 'SAR', 'AED'],
            onChanged: (v) => setState(() => _currency = v!),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _sectionTitle('Account'),
          const SizedBox(height: 12),
          _buildNavItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showDeleteAccountDialog(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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
    Color textColor = AppColors.white,
    Color iconColor = AppColors.textSecondary,
  }) {
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
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
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
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
              style: const TextStyle(color: AppColors.secondary, fontSize: 14),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
              icon: const Icon(
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
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(currentCtrl, 'Current Password', obscure: true),
            const SizedBox(height: 12),
            _dialogField(newCtrl, 'New Password', obscure: true),
            const SizedBox(height: 12),
            _dialogField(confirmCtrl, 'Confirm New Password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
            child: const Text('Update'),
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
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement account deletion logic
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
