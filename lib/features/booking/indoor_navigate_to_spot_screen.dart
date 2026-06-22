import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/booking/widgets/parking_spot_map.dart';

import 'active_session_screen.dart';

class IndoorNavigateToSpotScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final ParkingSlotModel slot;
  final VehicleModel vehicle;

  const IndoorNavigateToSpotScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.slot,
    required this.vehicle,
  });

  @override
  State<IndoorNavigateToSpotScreen> createState() =>
      _IndoorNavigateToSpotScreenState();
}

class _IndoorNavigateToSpotScreenState extends State<IndoorNavigateToSpotScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pathController;
  late final Animation<double> _pathAnim;

  late List<ParkingSlotModel> _slots;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _slots = _seedSlots();

    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pathAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pathController, curve: Curves.easeInOut),
    );

    _fetchSlots();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchSlots(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    try {
      final slots = await ParkingHardwareApiService.instance.fetchSlots(
        parkingLotId: widget.parkingLot.id,
      );
      if (!mounted) return;
      setState(() {
        _slots = _ensureTargetSlot(slots);
      });
    } catch (_) {
      // Keep the seeded map visible and retry on the next poll.
    }
  }

  void _onDone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          booking: widget.booking,
          parkingLot: widget.parkingLot,
          vehicle: widget.vehicle,
        ),
      ),
    );
  }

  List<ParkingSlotModel> _seedSlots() {
    final targetIndex = _fallbackTargetIndex();

    return List.generate(15, (index) {
      if (index == targetIndex) return widget.slot;

      final slotNum = 'S-${(index + 1).toString().padLeft(3, '0')}';
      return ParkingSlotModel(
        id: slotNum,
        parkingLotId: widget.parkingLot.id,
        slotNumber: slotNum,
        isAvailable: true,
        type: 'regular',
        level: widget.booking.level,
      );
    });
  }

  List<ParkingSlotModel> _ensureTargetSlot(List<ParkingSlotModel> liveSlots) {
    final slots = [...liveSlots];
    final targetIndex = _indexOfTarget(slots);
    if (targetIndex != -1) return slots;

    final fallbackIndex = _fallbackTargetIndex();
    if (fallbackIndex >= 0 && fallbackIndex < slots.length) {
      slots[fallbackIndex] = widget.slot;
    } else {
      slots.add(widget.slot);
    }
    return slots;
  }

  int _indexOfTarget(List<ParkingSlotModel> slots) {
    return slots.indexWhere(
      (slot) =>
          slot.id == widget.slot.id ||
          slot.slotNumber == widget.slot.slotNumber ||
          slot.id == widget.booking.slotId,
    );
  }

  int _fallbackTargetIndex() {
    final match = RegExp(r'(\d+)$').firstMatch(widget.slot.slotNumber);
    if (match == null) return 2;

    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return 2;
    return (parsed - 1).clamp(0, 14);
  }

  int get _targetIndex {
    final liveIndex = _indexOfTarget(_slots);
    return liveIndex == -1 ? _fallbackTargetIndex() : liveIndex;
  }

  String get _spotLabel {
    final label = widget.booking.spotLabel.trim();
    return label.isEmpty ? widget.slot.slotNumber : label;
  }

  String get _turnText {
    final rowName = String.fromCharCode(65 + (_targetIndex ~/ 4));
    final isLeft = _targetIndex % 4 < 2;
    return 'Turn ${isLeft ? 'left' : 'right'} at Zone $rowName';
  }

  IconData get _turnIcon =>
      _targetIndex % 4 < 2 ? Icons.turn_left_rounded : Icons.turn_right_rounded;

  int get _distanceMeters {
    final rows = ((_slots.length + 3) ~/ 4).clamp(4, 20);
    final targetRow = _targetIndex ~/ 4;
    return ((rows - targetRow).clamp(1, 10) * 5 + 10).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstructionCard(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: AnimatedBuilder(
                  animation: _pathAnim,
                  builder: (context, _) => ParkingSpotMap(
                    slots: _slots,
                    targetSlotId: widget.slot.slotNumber,
                    showRoute: true,
                    routeProgress: _pathAnim.value,
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 28, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  'Navigate to $_spotLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Follow the route to your spot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '1 min - $_distanceMeters m',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fieldStroke.withValues(alpha: 0.35),
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_turnIcon, color: Colors.black, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _turnText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'In ${_distanceMeters}m',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(color: AppColors.fieldStroke),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
