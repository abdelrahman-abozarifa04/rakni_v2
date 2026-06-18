import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// Terms of Service screen shown to users from Settings or during registration.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Terms of Service',
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
              child: Text(
                'Last updated: January 2025',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 24),

            _buildSection(
              'Agreement to Terms',
              'By downloading, installing, or using the Rakni mobile application '
              '("App"), you agree to be bound by these Terms of Service '
              '("Terms"). If you do not agree, please do not use the App.',
            ),

            _buildSection(
              'Use of the Service',
              'Rakni provides a platform for finding and reserving parking spots '
              'at participating locations in Egypt. You may use the App only for '
              'lawful purposes and in accordance with these Terms.\n\n'
              'You agree not to:\n\n'
              '• Use the App in any way that violates applicable laws or regulations.\n'
              '• Attempt to gain unauthorized access to any part of the system.\n'
              '• Use automated tools to scrape, crawl, or access the App.\n'
              '• Misrepresent your identity or vehicle information.',
            ),

            _buildSection(
              'Account Registration',
              'To use certain features, you must create an account. You are '
              'responsible for:\n\n'
              '• Providing accurate and up-to-date information.\n'
              '• Maintaining the confidentiality of your password.\n'
              '• All activity that occurs under your account.\n\n'
              'You must be at least 18 years old to create an account. By '
              'registering, you represent that you meet this requirement.',
            ),

            _buildSection(
              'Parking Reservations',
              'When you make a reservation through Rakni:\n\n'
              '• Reservations are subject to availability and confirmation.\n'
              '• The parking fee is deducted from your Rakni Wallet upon booking.\n'
              '• Cancellations made before the booking start time are eligible '
              'for a full refund to your Rakni Wallet.\n'
              '• Rakni is not responsible for incidents that occur at parking '
              'facilities, including theft, damage, or accidents.',
            ),

            _buildSection(
              'Rakni Wallet',
              'The Rakni Wallet is a pre-paid digital wallet for use within '
              'the App. Wallet credits:\n\n'
              '• Are non-transferable between accounts.\n'
              '• Cannot be exchanged for cash.\n'
              '• May be subject to expiration as specified at time of top-up.\n'
              '• Are subject to any applicable taxes and fees.',
            ),

            _buildSection(
              'Intellectual Property',
              'The App and its original content, features, and functionality '
              'are owned by Rakni and are protected by copyright, trademark, '
              'and other intellectual property laws. You may not reproduce, '
              'distribute, or create derivative works without our express '
              'written permission.',
            ),

            _buildSection(
              'Limitation of Liability',
              'To the maximum extent permitted by law, Rakni shall not be '
              'liable for any indirect, incidental, special, consequential, '
              'or punitive damages arising from your use of the App or any '
              'parking facility. Our total liability shall not exceed the '
              'amount paid by you for the specific booking in question.',
            ),

            _buildSection(
              'Termination',
              'We reserve the right to suspend or terminate your account at '
              'our sole discretion, without notice, for conduct that we believe '
              'violates these Terms or is harmful to other users, us, or third '
              'parties. You may also delete your account at any time via '
              'Settings → Account → Delete Account.',
            ),

            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance '
              'with the laws of the Arab Republic of Egypt, without regard to '
              'its conflict of law provisions.',
            ),

            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will '
              'provide notice of significant changes. Your continued use of the '
              'App after changes become effective constitutes acceptance.',
            ),

            _buildSection(
              'Contact Us',
              'For questions about these Terms, please contact us at:\n\n'
              'Email: legal@rakni.app\n'
              'Address: Cairo, Egypt',
            ),

            SizedBox(height: 32),
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
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
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
