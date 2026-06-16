import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// Privacy Policy screen shown to users from Settings or during onboarding.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Last updated: January 2025',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Introduction',
              'Welcome to Rakni ("we," "our," or "us"). We are committed to '
              'protecting your personal information and your right to privacy. '
              'This Privacy Policy explains how we collect, use, disclose, and '
              'safeguard your information when you use our mobile application '
              'and related services.',
            ),

            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, such as:\n\n'
              '• Account information: name, email address, phone number, and password.\n'
              '• Vehicle information: license plate number, car make, model, and color.\n'
              '• Payment information: wallet balance and transaction history.\n'
              '• Profile information: age, gender, and address.\n\n'
              'We also collect information automatically, including:\n\n'
              '• Location data to find nearby parking lots.\n'
              '• Device information (model, OS version, unique identifiers).\n'
              '• App usage data and crash reports (via Firebase Crashlytics).\n'
              '• FCM push notification tokens.',
            ),

            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide, maintain, and improve our parking reservation services.\n'
              '• Process bookings and payments through your Rakni Wallet.\n'
              '• Send booking confirmations, reminders, and status updates.\n'
              '• Respond to your comments and questions.\n'
              '• Monitor and analyze usage patterns to improve user experience.\n'
              '• Detect, investigate, and prevent fraudulent transactions.\n'
              '• Comply with legal obligations.',
            ),

            _buildSection(
              'Sharing Your Information',
              'We do not sell, trade, or otherwise transfer your personal '
              'information to third parties except as described below:\n\n'
              '• Service providers: Firebase (Google), Google Maps Platform, and '
              'payment processors who assist us in operating our application.\n'
              '• Legal requirements: when required by law or to protect our rights.\n'
              '• Business transfers: in connection with a merger, acquisition, or '
              'sale of assets.',
            ),

            _buildSection(
              'Data Security',
              'We implement appropriate technical and organizational measures to '
              'protect your personal information against unauthorized access, '
              'alteration, disclosure, or destruction. All data is transmitted '
              'over encrypted connections (HTTPS/TLS). However, no method of '
              'transmission over the Internet is 100% secure.',
            ),

            _buildSection(
              'Location Data',
              'Our app requests access to your device\'s location to show nearby '
              'parking lots and provide navigation. You may disable location '
              'access at any time in your device settings, but some features may '
              'be unavailable as a result.',
            ),

            _buildSection(
              'Data Retention',
              'We retain your personal data for as long as your account is active '
              'or as needed to provide our services. You may request deletion of '
              'your account and associated data at any time via the app\'s '
              'Settings → Account → Delete Account.',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our services are not directed to individuals under the age of 13. '
              'We do not knowingly collect personal information from children '
              'under 13. If we become aware that a child has provided us with '
              'personal information, we will delete it immediately.',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will '
              'notify you of any changes by updating the "Last updated" date '
              'at the top of this policy and, for significant changes, by '
              'sending a push notification.',
            ),

            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please '
              'contact us at:\n\n'
              'Email: privacy@rakni.app\n'
              'Address: Cairo, Egypt',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
