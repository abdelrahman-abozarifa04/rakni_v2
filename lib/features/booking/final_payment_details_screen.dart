import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/transaction_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/widgets/egyptian_license_plate.dart';

class FinalPaymentDetailsScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final VehicleModel vehicle;
  final DateTime exitTime;
  final double totalCost;

  const FinalPaymentDetailsScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.vehicle,
    required this.exitTime,
    required this.totalCost,
  });

  @override
  State<FinalPaymentDetailsScreen> createState() =>
      _FinalPaymentDetailsScreenState();
}

class _FinalPaymentDetailsScreenState
    extends State<FinalPaymentDetailsScreen> {
  String _selectedPayment = 'wallet';
  bool _paying = false;
  double _walletBalance = 0;
  bool _hasActiveSubscription = false;


  static const double _serviceFee = 5.0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _checkSubscription();
    // Pre-select booking's original payment method
    _selectedPayment = widget.booking.paymentMethod.isNotEmpty
        ? widget.booking.paymentMethod
        : 'wallet';
  }

  Future<void> _checkSubscription() async {
    try {
      final sub = await ParkingHardwareApiService.instance.checkActiveSubscription([widget.vehicle.plateNumber]);
      if (mounted) {
        setState(() {
          _hasActiveSubscription = sub != null;
        });
      }
    } catch (e) {
      debugPrint('[FinalPaymentDetails] Error checking subscription: $e');
    }
  }

  Future<void> _loadWallet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final wallet = await FirestoreService.instance.getWallet(uid);
    if (mounted) setState(() => _walletBalance = wallet?.balance ?? 0);
  }

  Duration get _duration =>
      widget.exitTime.difference(widget.booking.startTime);

  double get _overstayFee {
    // If exit time is after booked endTime, charge overstay
    if (widget.booking.endTime == null) return 0;
    if (widget.exitTime.isAfter(widget.booking.endTime!)) {
      final overstay =
          widget.exitTime.difference(widget.booking.endTime!).inSeconds /
              3600.0;
      return overstay * widget.booking.pricePerHour * 1.5; // 1.5x rate
    }
    return 0;
  }

  double get _total {
    if (_hasActiveSubscription) return 0;
    return widget.totalCost + _overstayFee + _serviceFee;
  }


  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _processPayment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_selectedPayment == 'wallet' && _walletBalance < _total) {
      _showSnack('Insufficient wallet balance.', AppColors.error);
      return;
    }

    setState(() => _paying = true);
    try {
      // Update booking to completed with exit time
      await FirestoreService.instance.updateBookingEndTime(
          widget.booking.id, widget.exitTime);
      await FirestoreService.instance.updateBookingStatus(
          widget.booking.id, 'completed');
      await FirestoreService.instance.updateBookingAmount(
          widget.booking.id, _total);

      // Release the slot in Firestore (source of truth)
      await FirestoreService.instance.updateSlotAvailability(
          widget.booking.parkingLotId, widget.booking.slotId, true);

      // Also release on the Django hardware backend (fire-and-forget)
      // so the physical occupancy sensor map refreshes for other users.
      ParkingHardwareApiService.instance
          .releaseSlot(slotId: widget.booking.slotId)
          .then((ok) {
        if (!ok) {
          debugPrint(
            '[FinalPayment] Hardware releaseSlot failed for '
            '${widget.booking.slotId} — Firestore already updated.',
          );
        }
      });

      // Deduct wallet if wallet payment
      if (_selectedPayment == 'wallet') {
        await FirestoreService.instance.updateWalletBalance(
            uid, _walletBalance - _total);
      }

      // Record transaction
      final tx = TransactionModel(
        id: '${widget.booking.id}_exit_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: widget.booking.id,
        userId: uid,
        amount: _total,
        paymentMethod: _selectedPayment,
        timestamp: DateTime.now(),
        status: 'success',
      );
      await FirestoreService.instance.recordTransaction(tx);

      // Trigger notification
      await FirestoreService.instance.sendAppNotification(
        uid,
        title: 'Session Completed',
        body: 'Your parking session for ${widget.vehicle.plateNumber} at ${widget.parkingLot.name} has ended. Total cost: EGP ${_total.toStringAsFixed(2)}.',
        type: 'payment_success',
        settingKey: 'setting_push_notifications',
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Payment failed: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.black, size: 40),
              ),
              SizedBox(height: 18),
              Text('Payment Successful!',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'EGP ${_total.toStringAsFixed(2)} paid successfully',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (r) => false),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Back to Home',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Details',
          style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plate recognition banner
                _buildPlateBanner(),
                SizedBox(height: 20),
                // Session summary
                _buildSectionTitle('Session Summary'),
                SizedBox(height: 10),
                _buildSessionSummary(),
                SizedBox(height: 20),
                // Payment method
                _buildSectionTitle('Payment Method'),
                SizedBox(height: 10),
                _buildPaymentOption('wallet',
                    Icons.account_balance_wallet_outlined,
                    'Digital Wallet',
                    'Balance: EGP ${_walletBalance.toStringAsFixed(2)}'),
                SizedBox(height: 8),
                _buildPaymentOption('visa', Icons.credit_card_outlined,
                    'Visa / Mastercard', 'Pay with card'),
                SizedBox(height: 20),
                // Pricing breakdown
                _buildSectionTitle('Pricing Breakdown'),
                SizedBox(height: 10),
                _buildPricingBreakdown(),
              ],
            ),
          ),
          // Bottom pay button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              color: AppColors.background,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _paying ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _paying
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _hasActiveSubscription
                              ? 'Complete Session (Premium)'
                              : 'Pay EGP ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14));
  }

  Widget _buildPlateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.surface
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          EgyptianLicensePlate(
            plateNumber: widget.vehicle.plateNumber,
            width: 140,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.vehicle.brand} ${widget.vehicle.model}',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Plate Recognized',
                        style: TextStyle(
                            color: Colors.green, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSummary() {
    final rows = [
      _SummaryRow(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: widget.parkingLot.name),
      _SummaryRow(
          icon: Icons.grid_view_rounded,
          label: 'Spot',
          value:
              '${widget.booking.level} · ${widget.booking.spotLabel}'),
      _SummaryRow(
          icon: Icons.login_rounded,
          label: 'Entry Time',
          value: _formatTime(widget.booking.startTime)),
      _SummaryRow(
          icon: Icons.logout_rounded,
          label: 'Exit Time',
          value: _formatTime(widget.exitTime)),
      _SummaryRow(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: _formatDuration(_duration)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(row.icon,
                        color: AppColors.secondary, size: 17),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(row.label,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ),
                    Text(row.value,
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                    color: AppColors.fieldStroke,
                    height: 1,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentOption(
      String id, IconData icon, String label, String sub) {
    final isSelected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : AppColors.fieldStroke),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.textSecondary,
                size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(sub,
                      style: TextStyle(
                          color: AppColors.hintColor, fontSize: 11)),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.fieldStroke,
                    width: 2),
                color: isSelected ? AppColors.secondary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: [
          _priceRow('Parking Fee',
              'EGP ${widget.totalCost.toStringAsFixed(2)}',
              AppColors.textSecondary),
          if (_overstayFee > 0) ...[
            SizedBox(height: 10),
            _priceRow('Overstay Fee (1.5x)',
                'EGP ${_overstayFee.toStringAsFixed(2)}', Colors.orange),
          ],
          SizedBox(height: 10),
          _priceRow('Service Fee',
              'EGP ${_serviceFee.toStringAsFixed(2)}',
              AppColors.textSecondary),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.fieldStroke, height: 1),
          ),
          _priceRow('Total', 'EGP ${_total.toStringAsFixed(2)}',
              AppColors.secondary,
              bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: bold ? AppColors.white : AppColors.textSecondary,
                fontSize: bold ? 15 : 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: bold ? 17 : 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}

class _SummaryRow {
  final IconData icon;
  final String label;
  final String value;
  _SummaryRow({required this.icon, required this.label, required this.value});
}
