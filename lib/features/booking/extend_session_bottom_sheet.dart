import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/transaction_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class ExtendSessionBottomSheet extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final VehicleModel vehicle;
  final void Function(BookingModel updatedBooking) onExtended;

  const ExtendSessionBottomSheet({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.vehicle,
    required this.onExtended,
  });

  @override
  State<ExtendSessionBottomSheet> createState() =>
      _ExtendSessionBottomSheetState();
}

class _ExtendSessionBottomSheetState extends State<ExtendSessionBottomSheet> {
  int _extendHours = 1;
  int _extendMinutes = 0;
  String _selectedPayment = 'wallet';
  bool _loading = false;
  double _walletBalance = 0;

  static const double _serviceFee = 5.0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final wallet = await FirestoreService.instance.getWallet(uid);
    if (mounted) setState(() => _walletBalance = wallet?.balance ?? 0);
  }

  double get _extensionFee {
    return widget.booking.pricePerHour *
        (_extendHours + _extendMinutes / 60.0);
  }

  double get _total => _extensionFee + _serviceFee;

  DateTime get _newEndTime {
    final current = widget.booking.endTime ?? DateTime.now();
    return current.add(
        Duration(hours: _extendHours, minutes: _extendMinutes));
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmExtension() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_selectedPayment == 'wallet' && _walletBalance < _total) {
      _showSnack('Insufficient wallet balance.', AppColors.error);
      return;
    }

    setState(() => _loading = true);
    try {
      // Update end time in Firestore
      await FirestoreService.instance.updateBookingEndTime(
          widget.booking.id, _newEndTime);

      // Update wallet if needed
      if (_selectedPayment == 'wallet') {
        await FirestoreService.instance.updateWalletBalance(
            uid, _walletBalance - _total);
      }

      // Record transaction
      final tx = TransactionModel(
        id: '${widget.booking.id}_extend_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: widget.booking.id,
        userId: uid,
        amount: _total,
        paymentMethod: _selectedPayment,
        timestamp: DateTime.now(),
        status: 'success',
      );
      await FirestoreService.instance.recordTransaction(tx);

      final updated = widget.booking.copyWith(endTime: _newEndTime);
      if (!mounted) return;
      widget.onExtended(updated);
      Navigator.pop(context);
      _showSnack(
          'Session extended by ${_extendHours}h ${_extendMinutes}m!',
          Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Extension failed: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fieldStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Extend Session',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Current session summary
            _buildSummaryCard(),
            const SizedBox(height: 20),
            // Extension controls
            _buildExtensionControls(),
            const SizedBox(height: 16),
            // New end time
            _buildNewEndTime(),
            const SizedBox(height: 20),
            // Payment selector
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Payment Method',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            const SizedBox(height: 10),
            _buildPaymentOption('wallet', Icons.account_balance_wallet_outlined,
                'Digital Wallet', 'Balance: EGP ${_walletBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildPaymentOption('visa', Icons.credit_card_outlined,
                'Visa / Mastercard', 'Pay with card'),
            const SizedBox(height: 20),
            // Price summary
            _buildPriceSummary(),
            const SizedBox(height: 24),
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmExtension,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        'Confirm & Pay — EGP ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: [
          _summaryRow('Reservation',
              '#${widget.booking.reservationId}'),
          const SizedBox(height: 8),
          _summaryRow('Vehicle',
              widget.vehicle.plateNumber),
          const SizedBox(height: 8),
          _summaryRow('Spot',
              '${widget.booking.level} · ${widget.booking.spotLabel}'),
          if (widget.booking.endTime != null) ...[
            const SizedBox(height: 8),
            _summaryRow('Current End',
                _formatTime(widget.booking.endTime!)),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildExtensionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extend By',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _buildSpinner(
                label: 'Hours',
                value: _extendHours,
                onIncrement: () {
                  if (_extendHours < 12) {
                    setState(() => _extendHours++);
                  }
                },
                onDecrement: () {
                  if (_extendHours > 0) {
                    setState(() => _extendHours--);
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(':',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
              // Minutes
              _buildSpinner(
                label: 'Minutes',
                value: _extendMinutes,
                step: 30,
                onIncrement: () {
                  setState(() {
                    _extendMinutes = (_extendMinutes + 30) % 60;
                  });
                },
                onDecrement: () {
                  setState(() {
                    _extendMinutes =
                        (_extendMinutes - 30 + 60) % 60;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    int step = 1,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.fieldStroke),
            ),
            child: const Icon(Icons.keyboard_arrow_up,
                color: AppColors.secondary, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(value.toString().padLeft(2, '0'),
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.fieldStroke),
            ),
            child: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.secondary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildNewEndTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.update_outlined,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text('New End Time',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          Text(
            _formatTime(_newEndTime),
            style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, IconData icon, String label, String sub) {
    final isSelected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : AppColors.fieldColor,
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
            const SizedBox(width: 10),
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
                      style: const TextStyle(
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
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: [
          _priceRow('Extension fee', 'EGP ${_extensionFee.toStringAsFixed(2)}',
              AppColors.textSecondary),
          const SizedBox(height: 8),
          _priceRow('Service fee', 'EGP ${_serviceFee.toStringAsFixed(2)}',
              AppColors.textSecondary),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.fieldStroke, height: 1),
          ),
          _priceRow('Total', 'EGP ${_total.toStringAsFixed(2)}',
              AppColors.secondary,
              bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: bold ? AppColors.white : AppColors.textSecondary,
                fontSize: bold ? 14 : 12,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: bold ? 16 : 12,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
