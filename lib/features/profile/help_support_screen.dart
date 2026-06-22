import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $urlString'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style:
              TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fieldStroke),
            ),
            child: TextField(
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 28),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.chat_outlined,
                  label: 'Live Chat',
                  onTap: () => _launchUrl(
                    context,
                    'https://wa.me/201097457086',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  onTap: () => _launchUrl(
                    context,
                    'mailto:as0144549@gmail.com',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Call Us',
                  onTap: () => _launchUrl(
                    context,
                    'tel:+201097457086',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),

          // FAQ Section
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ..._faqs.map((faq) => _buildFaqItem(context, faq)),

          SizedBox(height: 24),

          // Other Support Options
          Text(
            'More Options',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildOptionItem(
            icon: Icons.book_outlined,
            title: 'User Guide',
            subtitle: 'How to use Rakni',
            onTap: () => _launchUrl(context, 'https://rakni.app/guide'),
          ),
          SizedBox(height: 8),
          _buildOptionItem(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () => _showReportSheet(context),
          ),
          SizedBox(height: 8),
          _buildOptionItem(
            icon: Icons.star_outline,
            title: 'Rate the App',
            subtitle: 'Leave us a review on the store',
            onTap: () => _launchUrl(
              context,
              'market://details?id=com.rakniteam.rakni_v2',
            ),
          ),
          SizedBox(height: 8),
          _buildOptionItem(
            icon: Icons.info_outline,
            title: 'About Rakni',
            subtitle: 'Version 2.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, _Faq faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          faq.question,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Text(
            faq.answer,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, color: AppColors.textSecondary, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Report a Bug',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              style: TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.fieldStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.secondary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bug report submitted. Thank you!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: Text('Submit Report',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('About Rakni',
            style: TextStyle(color: AppColors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_parking,
                  color: AppColors.secondary, size: 40),
            ),
            SizedBox(height: 16),
            Text('Rakni',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Version 2.0.0',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'Your smart parking companion — find, book, and manage parking spots with ease.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq(
    'How do I book a parking spot?',
    'Open the Map tab, select a parking lot near you, choose an available slot, pick your duration, and complete the booking process.',
  ),
  _Faq(
    'Can I cancel my booking?',
    'Yes. Go to My Bookings, select the active booking, and tap "Cancel". Cancellations made more than 1 hour before start time are fully refunded.',
  ),
  _Faq(
    'How do I add a vehicle?',
    'Go to Profile → My Vehicles, then tap the "+" button and fill in your vehicle details.',
  ),
  _Faq(
    'What payment methods are accepted?',
    'We accept Visa, Mastercard, Apple Pay, Google Pay, and the Rakni Wallet.',
  ),
  _Faq(
    'How do I extend my parking session?',
    'Open the active booking from the Bookings tab and tap "Extend Session".',
  ),
  _Faq(
    'Is my payment information secure?',
    'Yes. All payment information is encrypted and processed through a PCI-DSS compliant payment gateway. We never store your raw card data.',
  ),
];
