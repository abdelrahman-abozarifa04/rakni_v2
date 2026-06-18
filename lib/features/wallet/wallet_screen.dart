import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rakni_v2/core/models/transaction_model.dart';
import 'package:rakni_v2/core/models/wallet_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
import 'package:rakni_v2/features/transactions/transaction_history_screen.dart';
import 'package:rakni_v2/features/wallet/top_up_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  WalletModel? _wallet;
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final wallet = await FirestoreService.instance.getWallet(uid);
      final txStream =
          FirestoreService.instance.streamUserTransactions(uid);
      final txList = await txStream.first;
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _recentTransactions = txList.take(5).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
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
          icon: Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Wallet',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBalanceCard(),
                  SizedBox(height: 24),
                  _buildAddMoneyButton(context),
                  SizedBox(height: 28),
                  _buildRecentTransactions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final isDark = ThemeService.instance.isDark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF3D5A1E), Color(0xFF2A3D12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF9FBF0), Color(0xFFECF3D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.4 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.secondary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: isDark ? AppColors.secondary : const Color(0xFF4A5C00),
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Rakni Wallet',
                style: TextStyle(
                  color: isDark ? AppColors.secondary : const Color(0xFF4A5C00),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: isDark ? AppColors.secondary : const Color(0xFF4A5C00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Available Balance',
            style: TextStyle(
              color: isDark ? const Color(0xFFB0B8A0) : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'EGP ${(_wallet?.balance ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _wallet != null
                ? 'Last updated: ${_relativeTime(_wallet!.lastUpdated)}'
                : '',
            style: TextStyle(
              color: isDark ? const Color(0xFFB0B8A0) : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoneyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const TopUpScreen()),
          );
          if (added == true && mounted) {
            _loadData();
          }
        },
        icon: Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Add Money',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        if (_recentTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._recentTransactions.map((tx) => _MiniTransactionTile(
                transaction: tx,
                relativeTime: _relativeTime(tx.timestamp),
              )),
      ],
    );
  }
}

class _MiniTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String relativeTime;

  const _MiniTransactionTile({
    required this.transaction,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    final isTopUp = transaction.bookingId.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isTopUp
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTopUp
                  ? Icons.add_circle_outline
                  : Icons.local_parking_outlined,
              color:
                  isTopUp ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTopUp ? 'Wallet Top-up' : 'Parking Booking',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  relativeTime,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isTopUp ? '+' : '-'}EGP ${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isTopUp ? AppColors.accent : AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
