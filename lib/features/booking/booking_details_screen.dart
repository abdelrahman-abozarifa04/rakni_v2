import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/booking_service.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'booking_spot_selection_screen.dart';
import 'booking_confirmed_screen.dart';


class BookingDetailsScreen extends StatefulWidget {
  final ParkingLotModel parkingLot;

  const BookingDetailsScreen({super.key, required this.parkingLot});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _firestoreService = FirestoreService.instance;

  // Form state
  VehicleModel? _selectedVehicle;
  ParkingSlotModel? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _fromTime = TimeOfDay.now();
  int _durationHours = 2;
  final int _durationMinutes = 0; // not final — modified by stepper
  String _selectedPayment = 'wallet';
  final TextEditingController _promoController = TextEditingController();
  double _promoDiscount = 0;
  bool _promoApplied = false;

  // Loaded data
  List<VehicleModel> _vehicles = [];
  double _walletBalance = 0;
  bool _loading = true;
  bool _confirming = false;
  String? _error;
  bool _hasActiveSubscription = false;

  static const double _serviceFee = 5.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final vehicles =
          await _firestoreService.streamVehicles(uid).first;
      final wallet = await _firestoreService.getWallet(uid);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle = vehicles.isNotEmpty
            ? (vehicles.any((v) => v.isDefault)
                ? vehicles.firstWhere((v) => v.isDefault)
                : vehicles.first)
            : null;
        _walletBalance = wallet?.balance ?? 0;
        _loading = false;
      });
      if (_selectedVehicle != null) {
        await _checkSubscription(_selectedVehicle);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _checkSubscription(VehicleModel? vehicle) async {
    if (vehicle == null) {
      setState(() => _hasActiveSubscription = false);
      return;
    }
    try {
      final sub = await ParkingHardwareApiService.instance.checkActiveSubscription([vehicle.plateNumber]);
      if (mounted) {
        setState(() {
          _hasActiveSubscription = sub != null;
        });
      }
    } catch (e) {
      debugPrint('[BookingDetails] Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _hasActiveSubscription = false;
        });
      }
    }
  }


  double get _subtotal {
    if (_hasActiveSubscription) return 0;
    return widget.parkingLot.pricePerHour *
        (_durationHours + _durationMinutes / 60);
  }

  double get _total {
    if (_hasActiveSubscription) return 0;
    return _subtotal + _serviceFee - _promoDiscount;
  }


  TimeOfDay get _toTime {
    final fromMinutes = _fromTime.hour * 60 + _fromTime.minute;
    final toMinutes = fromMinutes + _durationHours * 60 + _durationMinutes;
    return TimeOfDay(
        hour: (toMinutes ~/ 60) % 24, minute: toMinutes % 60);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.secondary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectFromTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fromTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.secondary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _fromTime = picked);
    }
  }

  Future<void> _pickSlot() async {
    final result = await Navigator.push<ParkingSlotModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BookingSpotSelectionScreen(parkingLot: widget.parkingLot),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedSlot = result);
    }
  }

  Future<void> _confirmAndPay() async {
    if (_selectedVehicle == null) {
      _showError('Please select a vehicle.');
      return;
    }
    if (_selectedSlot == null) {
      _showError('Please select a parking spot.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_selectedPayment == 'wallet' && _walletBalance < _total) {
      _showError('Insufficient wallet balance.');
      return;
    }

    setState(() => _confirming = true);
    try {
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _fromTime.hour,
        _fromTime.minute,
      );
      final endTime = startTime.add(
          Duration(hours: _durationHours, minutes: _durationMinutes));

      final confirmedBooking = await BookingService.instance.createBooking(
        uid: uid,
        lot: widget.parkingLot,
        slot: _selectedSlot!,
        startTime: startTime,
        endTime: endTime,
        total: _total,
        vehicleId: _selectedVehicle!.id,
        vehiclePlate: _selectedVehicle!.plateNumber,
        paymentMethod: _selectedPayment,
        walletBalance: _walletBalance,
        promoDiscount: _promoDiscount,
      );

      // Trigger notification
      await FirestoreService.instance.sendAppNotification(
        uid,
        title: 'Booking Confirmed',
        body: 'Your spot ${_selectedSlot!.slotNumber} at ${widget.parkingLot.name} has been booked.',
        type: 'booking_success',
        settingKey: 'setting_push_notifications',
      );

      // Notify the Django hardware backend to flip the physical slot's
      // is_occupied flag immediately so other users see the spot as taken
      // on their next 5-second poll. Fire-and-forget — the Firestore booking
      // is already saved, so we never block confirmation on this call.
      ParkingHardwareApiService.instance
          .reserveSlot(
        slotId: _selectedSlot!.id,
        plateNumber: _selectedVehicle!.plateNumber,
      )
          .then((ok) {
        if (!ok) {
          debugPrint(
            '[BookingDetails] Hardware slot ${_selectedSlot!.id} reserve call '
            'failed — Firestore booking is still valid.',
          );
        }
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedScreen(
            booking: confirmedBooking,
            parkingLot: widget.parkingLot,
            slot: _selectedSlot!,
            vehicle: _selectedVehicle!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Payment failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showError(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
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
          'Booking Details',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 48),
        SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadInitialData,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text('Retry', style: TextStyle(color: Colors.black)),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lot Info Card
              _buildLotCard(),
              SizedBox(height: 20),
              // Vehicle Selector
              _buildSectionTitle('Select Vehicle'),
              SizedBox(height: 10),
              _buildVehicleSelector(),
              SizedBox(height: 20),
              // Spot Selector
              _buildSectionTitle('Parking Spot'),
              SizedBox(height: 10),
              _buildSpotField(),
              SizedBox(height: 20),
              // Date & Time
              _buildSectionTitle('Date & Time'),
              SizedBox(height: 10),
              _buildDateTimeSection(),
              SizedBox(height: 20),
              // Payment Method
              _buildSectionTitle('Payment Method'),
              SizedBox(height: 10),
              _buildPaymentSelector(),
              SizedBox(height: 20),
              // Promo Code
              _buildSectionTitle('Promo Code'),
              SizedBox(height: 10),
              _buildPromoField(),
              SizedBox(height: 20),
              // Price Summary
              _buildPriceSummary(),
            ],
          ),
        ),
        // Bottom CTA
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            color: AppColors.background,
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _confirming ? null : _confirmAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                  child: _confirming
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _hasActiveSubscription
                              ? 'Confirm Booking (Premium)'
                              : 'Confirm & Pay — EGP ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildLotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        children: [
          // Lot image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.fieldColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.parkingLot.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(widget.parkingLot.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.local_parking,
                            color: AppColors.secondary,
                            size: 32)))
                : Icon(Icons.local_parking,
                    color: AppColors.secondary, size: 32),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.parkingLot.name,
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(widget.parkingLot.address,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: AppColors.secondary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'EGP ${widget.parkingLot.pricePerHour.toStringAsFixed(0)}/hr',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 4),
                    Text('${widget.parkingLot.availableSlots} spots',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector() {
    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Row(children: [
          Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Text('No vehicles found. Add one in your profile.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: DropdownButton<VehicleModel>(
        value: _selectedVehicle,
        isExpanded: true,
        dropdownColor: AppColors.surface,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
        items: _vehicles.map((v) {
          return DropdownMenuItem(
            value: v,
            child: Row(
              children: [
                Icon(Icons.directions_car, color: AppColors.secondary, size: 20),
                SizedBox(width: 10),
                Text(
                  '${v.brand} ${v.model} — ${v.plateNumber}',
                  style: TextStyle(color: AppColors.white, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          setState(() => _selectedVehicle = v);
          _checkSubscription(v);
        },
      ),
    );
  }

  Widget _buildSpotField() {
    return GestureDetector(
      onTap: _pickSlot,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _selectedSlot != null
                  ? AppColors.secondary
                  : AppColors.fieldStroke),
        ),
        child: Row(
          children: [
            Icon(Icons.grid_view_rounded,
                color: _selectedSlot != null
                    ? AppColors.secondary
                    : AppColors.textSecondary,
                size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedSlot != null
                    ? 'Spot ${_selectedSlot!.slotNumber}'
                    : 'Tap to select a spot',
                style: TextStyle(
                    color: _selectedSlot != null
                        ? AppColors.white
                        : AppColors.hintColor,
                    fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      children: [
        // Date
        _buildTappableRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value:
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          onTap: _selectDate,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTappableRow(
                icon: Icons.access_time_outlined,
                label: 'From',
                value: _fromTime.format(context),
                onTap: _selectFromTime,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildTappableRow(
                icon: Icons.access_time_rounded,
                label: 'To',
                value: _toTime.format(context),
                onTap: null,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        // Duration stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.fieldColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fieldStroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Row(
                children: [
                  _stepperBtn(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          if (_durationHours > 1) _durationHours--;
                        });
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${_durationHours.toString().padLeft(2, '0')}h : ${_durationMinutes.toString().padLeft(2, '0')}m',
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                  _stepperBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          if (_durationHours < 24) _durationHours++;
                        });
                      }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTappableRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 18),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.hintColor, fontSize: 11)),
                Text(value,
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Icon(icon, color: AppColors.white, size: 16),
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Column(
      children: [
        _buildPaymentOption(
          id: 'wallet',
          icon: Icons.account_balance_wallet_outlined,
          label: 'Digital Wallet',
          subtitle: 'Balance: EGP ${_walletBalance.toStringAsFixed(2)}',
        ),
        SizedBox(height: 8),
        _buildPaymentOption(
          id: 'visa',
          icon: Icons.credit_card_outlined,
          label: 'Visa / Mastercard',
          subtitle: 'Pay with card',
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.fieldStroke),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color:
                      isSelected ? AppColors.secondary : AppColors.textSecondary,
                  size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(
                        color: AppColors.hintColor, fontSize: 11)),
              ],
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
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
                  ? Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _promoController,
            style: TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Enter promo code',
              hintStyle: TextStyle(color: AppColors.hintColor),
              prefixIcon: Icon(Icons.discount_outlined,
                  color: AppColors.secondary, size: 20),
              filled: true,
              fillColor: AppColors.fieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.fieldStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.fieldStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.secondary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // Demo: code "RAKNI20" gives 20 EGP off
              if (_promoController.text.trim().toUpperCase() == 'RAKNI20') {
                setState(() {
                  _promoDiscount = 20;
                  _promoApplied = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Promo applied: EGP 20 off!'),
                  backgroundColor: Colors.green,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invalid promo code.'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _promoApplied ? Colors.green : AppColors.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _promoApplied ? 'Applied!' : 'Apply',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: [
          _buildPriceRow('Parking fee',
              'EGP ${_subtotal.toStringAsFixed(2)}', AppColors.textSecondary),
          SizedBox(height: 10),
          _buildPriceRow('Service fee',
              'EGP ${_serviceFee.toStringAsFixed(2)}', AppColors.textSecondary),
          if (_promoApplied) ...[
            SizedBox(height: 10),
            _buildPriceRow('Promo discount',
                '- EGP ${_promoDiscount.toStringAsFixed(2)}', Colors.green),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.fieldStroke, height: 1),
          ),
          _buildPriceRow(
              'Total', 'EGP ${_total.toStringAsFixed(2)}', AppColors.secondary,
              bold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: bold ? AppColors.white : AppColors.textSecondary,
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: bold ? 17 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
