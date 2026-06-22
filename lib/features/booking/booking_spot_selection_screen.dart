import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/booking/widgets/parking_spot_map.dart';

class BookingSpotSelectionScreen extends StatefulWidget {
  final ParkingLotModel parkingLot;

  const BookingSpotSelectionScreen({super.key, required this.parkingLot});

  @override
  State<BookingSpotSelectionScreen> createState() =>
      _BookingSpotSelectionScreenState();
}

class _BookingSpotSelectionScreenState
    extends State<BookingSpotSelectionScreen> {
  static const _pollInterval = Duration(seconds: 5);

  List<ParkingSlotModel> _slots = [];
  ParkingSlotModel? _selectedSlot;
  bool _loading = true;
  bool _confirming = false;
  String? _error;
  DateTime _lastUpdated = DateTime.now();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSlots(showLoading: true);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchSlots());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSlots({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final slots = await ParkingHardwareApiService.instance.fetchSlots(
        parkingLotId: widget.parkingLot.id,
      );
      if (!mounted) return;

      // If the slot the user had selected just got taken (or vanished
      // entirely), drop the selection and tell them.
      ParkingSlotModel? stillSelected;
      if (_selectedSlot != null) {
        final match = slots.where((s) => s.id == _selectedSlot!.id);
        if (match.isNotEmpty && match.first.isAvailable) {
          stillSelected = match.first;
        } else if (match.isNotEmpty && !match.first.isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This spot was just taken. Please choose another.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }

      setState(() {
        _slots = slots;
        _selectedSlot = stillSelected;
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load live slot data: ${e.toString()}';
      });
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedSlot == null || _confirming) return;
    setState(() => _confirming = true);

    // Final real-time re-check right before handing the slot back, so we
    // never confirm a spot that became occupied seconds ago.
    try {
      final freshSlots = await ParkingHardwareApiService.instance.fetchSlots(
        parkingLotId: widget.parkingLot.id,
      );
      final fresh = freshSlots.where((s) => s.id == _selectedSlot!.id);

      if (fresh.isEmpty || !fresh.first.isAvailable) {
        if (!mounted) return;
        setState(() {
          _confirming = false;
          _slots = freshSlots;
          _selectedSlot = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This spot was just taken. Please choose another.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, fresh.first);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not confirm spot: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _selectedSlot == null
          ? null
          : SafeArea(child: _buildSelectionBar()),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Parking Spot',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Choose your preferred parking location',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
            tooltip: 'Refresh',
            onPressed: () => _fetchSlots(showLoading: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final secondsAgo = DateTime.now().difference(_lastUpdated).inSeconds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            _loading ? 'Updating...' : 'Live - Updated ${secondsAgo}s ago',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          if (_slots.isNotEmpty)
            Text(
              '${_slots.where((s) => s.isAvailable).length}/${_slots.length} available',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _slots.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }
    if (_error != null && _slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchSlots(showLoading: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Center(
        child: Text(
          'No parking slots reported by the system yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ParkingSpotMap(
        slots: _slots,
        selectedSlotId: _selectedSlot?.id,
        onSlotTap: (slot) => setState(() => _selectedSlot = slot),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Selected Spot',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (_selectedSlot!.level.isNotEmpty)
                  Text(
                    _selectedSlot!.level,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  _selectedSlot!.slotNumber,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirming ? null : _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _confirming
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
