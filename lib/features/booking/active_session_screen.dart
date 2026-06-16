import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'extend_session_bottom_sheet.dart';
import 'gate_exit_scan_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final VehicleModel vehicle;

  const ActiveSessionScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.vehicle,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _dotController;
  late final Animation<double> _ringAnim;
  late final Animation<double> _dotAnim;
  Timer? _timer;

  Duration _elapsed = Duration.zero;
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;

    // Calculate elapsed from startTime
    _elapsed = DateTime.now().difference(_booking.startTime);
    if (_elapsed.isNegative) _elapsed = Duration.zero;

    // Circular ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3600), // 1 hour full ring
    );
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // Dot pulsing
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _dotAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOut),
    );

    // Start ring from elapsed position
    final totalSec = _booking.endTime != null
        ? _booking.endTime!.difference(_booking.startTime).inSeconds.toDouble()
        : 7200.0; // default 2h
    _ringController.value =
        math.min(_elapsed.inSeconds / totalSec, 0.99);
    _ringController.forward();

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_booking.startTime);
        if (_elapsed.isNegative) _elapsed = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  double get _currentCost {
    final hours = _elapsed.inSeconds / 3600.0;
    return hours * _booking.pricePerHour;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showExtendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExtendSessionBottomSheet(
        booking: _booking,
        parkingLot: widget.parkingLot,
        vehicle: widget.vehicle,
        onExtended: (updatedBooking) {
          setState(() => _booking = updatedBooking);
        },
      ),
    );
  }

  void _endSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GateExitScanScreen(
          booking: _booking,
          parkingLot: widget.parkingLot,
          vehicle: widget.vehicle,
          elapsedCost: _currentCost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Session',
          style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular timer ring
            _buildTimerRing(),
            const SizedBox(height: 24),
            // Cost card
            _buildCostCard(),
            const SizedBox(height: 16),
            // Session details
            _buildSessionDetails(),
            const SizedBox(height: 28),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showExtendSheet,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.fieldStroke),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Extend Session',
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _endSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'End Session',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRing() {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          AnimatedBuilder(
            animation: _dotAnim,
            builder: (context, child) => Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary
                        .withValues(alpha: 0.08 * _dotAnim.value),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Ring
          AnimatedBuilder(
            animation: _ringAnim,
            builder: (context, child) => CustomPaint(
              size: const Size(220, 220),
              painter: _RingPainter(
                progress: _ringAnim.value,
                elapsed: _elapsed,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "Active Session" pill
              AnimatedBuilder(
                animation: _dotAnim,
                builder: (context, child) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green
                            .withValues(alpha: _dotAnim.value),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Active Session',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Time display
              Text(
                _formatDuration(_elapsed),
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 4),
              Text(
                'EGP ${_currentCost.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCostItem(
              label: 'Entry Time',
              value: _formatTime(_booking.startTime),
              icon: Icons.login_rounded,
            ),
          ),
          Container(
              width: 1, height: 40, color: AppColors.fieldStroke),
          Expanded(
            child: _buildCostItem(
              label: 'Rate',
              value: 'EGP ${_booking.pricePerHour.toStringAsFixed(0)}/hr',
              icon: Icons.local_offer_outlined,
            ),
          ),
          Container(
              width: 1, height: 40, color: AppColors.fieldStroke),
          Expanded(
            child: _buildCostItem(
              label: 'Current Cost',
              value: 'EGP ${_currentCost.toStringAsFixed(2)}',
              icon: Icons.payments_outlined,
              valueColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem({
    required String label,
    required String value,
    required IconData icon,
    Color valueColor = AppColors.white,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 18),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 12),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSessionDetails() {
    final details = [
      _DetailItem(
          icon: Icons.directions_car_outlined,
          label: 'Vehicle',
          value:
              '${widget.vehicle.brand} ${widget.vehicle.model} · ${widget.vehicle.plateNumber}'),
      _DetailItem(
          icon: Icons.confirmation_number_outlined,
          label: 'Reservation ID',
          value: '#${_booking.reservationId}'),
      _DetailItem(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: _booking.lotName.isNotEmpty
              ? _booking.lotName
              : widget.parkingLot.name),
      _DetailItem(
          icon: Icons.grid_view_rounded,
          label: 'Parking Spot',
          value: '${_booking.level} · ${_booking.spotLabel}'),
      _DetailItem(
          icon: Icons.schedule_outlined,
          label: 'Time Slot',
          value: _booking.endTime != null
              ? '${_formatTime(_booking.startTime)} → ${_formatTime(_booking.endTime!)}'
              : '${_formatTime(_booking.startTime)} → --'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: details.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildDetailRow(item),
              if (i < details.length - 1)
                const Divider(
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

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(item.icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem({required this.icon, required this.label, required this.value});
}

/// CustomPainter for the animated ring
class _RingPainter extends CustomPainter {
  final double progress;
  final Duration elapsed;

  _RingPainter({required this.progress, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = -math.pi / 2; // start from top

    // Track (background ring)
    final trackPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (lime)
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.6),
          AppColors.secondary,
        ],
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi * math.min(progress, 1.0),
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * math.min(progress, 1.0),
      false,
      progressPaint,
    );

    // Tip dot
    if (progress > 0.02) {
      final angle = startAngle + 2 * math.pi * progress;
      final dotPos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
          dotPos, 7, Paint()..color = AppColors.secondary);
      canvas.drawCircle(
          dotPos,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.elapsed != elapsed;
}
