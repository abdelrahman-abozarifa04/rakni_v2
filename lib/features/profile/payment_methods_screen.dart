import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/theme_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Mock payment methods — replace with real Firestore data when backend is ready
  final List<_PaymentMethod> _methods = [
    _PaymentMethod(
      type: 'Visa',
      last4: '4242',
      expiry: '12/26',
      isDefault: true,
    ),
    _PaymentMethod(
      type: 'Mastercard',
      last4: '8888',
      expiry: '06/25',
      isDefault: false,
    ),
  ];

  void _showAddCardSheet() {
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  color: AppColors.textSecondary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Add New Card',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _sheetField(nameCtrl, 'Cardholder Name', Icons.person_outline),
            SizedBox(height: 12),
            _sheetField(
              numberCtrl,
              'Card Number',
              Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sheetField(
                    expiryCtrl,
                    'MM/YY',
                    Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _sheetField(
                    cvvCtrl,
                    'CVV',
                    Icons.lock_outline,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Card added successfully!'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                child: Text(
                  'Add Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  IconData _cardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card_outlined;
      default:
        return Icons.payment_outlined;
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
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Methods',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.accent,
              size: 26,
            ),
            onPressed: _showAddCardSheet,
            tooltip: 'Add Card',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._methods.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: m.isDefault
                    ? (ThemeService.instance.isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF2A2A2B), Color(0xFF3D3F3F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [AppColors.surface, const Color(0xFFF2F3F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ))
                    : null,
                color: m.isDefault ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: m.isDefault
                    ? Border.all(color: AppColors.accent, width: 1.5)
                    : null,
                boxShadow: ThemeService.instance.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: m.isDefault ? 0.06 : 0.03),
                          blurRadius: m.isDefault ? 12 : 8,
                          offset: Offset(0, m.isDefault ? 4 : 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.isDefault
                          ? AppColors.accent.withAlpha(26)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _cardIcon(m.type),
                      color: m.isDefault
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m.type} •••• ${m.last4}',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Expires ${m.expiry}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (m.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var j = 0; j < _methods.length; j++) {
                                _methods[j] = _PaymentMethod(
                                  type: _methods[j].type,
                                  last4: _methods[j].last4,
                                  expiry: _methods[j].expiry,
                                  isDefault: j == i,
                                );
                              }
                            });
                          },
                          child: Text(
                            'Set Default',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _methods.removeAt(i));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddCardSheet,
            icon: Icon(Icons.add, color: AppColors.accent),
            label: Text(
              'Add New Card',
              style: TextStyle(color: AppColors.accent),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),

          SizedBox(height: 32),
          Text(
            'Other Payment Options',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildOtherOption(
            Icons.account_balance_wallet_outlined,
            'Rakni Wallet',
            'EGP 0.00',
          ),
          SizedBox(height: 12),
          _buildOtherOption(Icons.apple, 'Apple Pay', 'Connect your Apple Pay'),
          SizedBox(height: 12),
          _buildOtherOption(
            Icons.g_mobiledata_outlined,
            'Google Pay',
            'Connect your Google Pay',
          ),
        ],
      ),
    );
  }

  Widget _buildOtherOption(IconData icon, String title, String subtitle) {
    return Container(
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
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          SizedBox(width: 16),
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
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String type;
  final String last4;
  final String expiry;
  final bool isDefault;

  _PaymentMethod({
    required this.type,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });
}
