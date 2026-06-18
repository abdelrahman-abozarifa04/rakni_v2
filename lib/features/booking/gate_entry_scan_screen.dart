import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'indoor_navigate_to_spot_screen.dart';

class GateEntryScanScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final ParkingSlotModel slot;
  final VehicleModel vehicle;

  const GateEntryScanScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.slot,
    required this.vehicle,
  });

  @override
  State<GateEntryScanScreen> createState() => _GateEntryScanScreenState();
}

class _GateEntryScanScreenState extends State<GateEntryScanScreen>
    with TickerProviderStateMixin {
  bool _recognized = false;
  bool _navigating = false;

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnim;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Scan line animation (0 → 1 → 0 repeat)
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulse for recognized state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate ANPR recognition after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _recognized = true);
      _scanLineController.stop();
      // Auto-advance to Screen 6 after 3 more seconds
      Future.delayed(const Duration(seconds: 3), _advanceToIndoor);
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _advanceToIndoor() async {
    if (!mounted || _navigating) return;
    _navigating = true;

    try {
      // Mark booking as active in Firestore
      await FirestoreService.instance
          .updateBookingStatus(widget.booking.id, 'active');
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IndoorNavigateToSpotScreen(
          booking: widget.booking.copyWith(status: 'active'),
          parkingLot: widget.parkingLot,
          slot: widget.slot,
          vehicle: widget.vehicle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.parkingLot.name,
                            style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(widget.parkingLot.address,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Main scan card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fieldStroke),
                  ),
                  child: Column(
                    children: [
                      // Title bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (context, child) => Transform.scale(
                                    scale: _pulseAnim.value,
                                    child: Icon(Icons.wifi_tethering,
                                        color: AppColors.secondary, size: 20),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _recognized ? 'ENTRY SCAN' : 'ENTRY SCAN',
                                  style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 1.2),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.fieldStroke),
                              ),
                              child: Icon(Icons.help_outline,
                                  color: AppColors.textSecondary, size: 16),
                            ),
                          ],
                        ),
                      ),
                      Text('AI PLATE RECOGNITION',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 12),
                      // Viewfinder
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _recognized
                              ? _buildRecognizedView()
                              : _buildScanningView(),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Status text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _recognized
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Access Granted: Entry Gate Opening',
                                    key: const ValueKey('granted'),
                                    style: TextStyle(
                                        color: Colors.green.shade300,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              )
                            : Text(
                                'Please wait while scanning...',
                                key: ValueKey('scanning'),
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                      ),
                      SizedBox(height: 16),
                      // Instructions
                      _buildInstructions(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom fallback buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  Text('Issues scanning?',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.qr_code_2,
                              color: AppColors.white, size: 18),
                          label: Text('Scan QR Code',
                              style: TextStyle(color: AppColors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.fieldStroke),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.keyboard,
                              color: AppColors.white, size: 18),
                          label: Text('Manual Entry',
                              style: TextStyle(color: AppColors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.fieldStroke),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Camera placeholder (dark bg with car icon)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car,
                      color: Color(0xFF444444), size: 80),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.secondary, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PLATE',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          ),
          // Corner brackets
          ..._buildCornerBrackets(AppColors.secondary),
          // ANPR enabled badge
          Positioned(
            top: 10,
            left: 10,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 6),
                Text('ANPR System enabled',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Scan line
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (ctx, _) {
              return Positioned(
                top: _scanLineAnim.value *
                    (MediaQuery.of(ctx).size.width * 0.7),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.secondary.withValues(alpha: 0.7),
                        AppColors.secondary,
                        AppColors.secondary.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car,
                      color: Color(0xFF666666), size: 72),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      widget.vehicle.plateNumber,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Green corners
          ..._buildCornerBrackets(Colors.green),
          // Check badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color) {
    const size = 22.0;
    const thickness = 2.5;
    return [
      Positioned(
          top: 12,
          left: 12,
          child: _bracket(color, size, thickness, true, true)),
      Positioned(
          top: 12,
          right: 12,
          child: _bracket(color, size, thickness, true, false)),
      Positioned(
          bottom: 12,
          left: 12,
          child: _bracket(color, size, thickness, false, true)),
      Positioned(
          bottom: 12,
          right: 12,
          child: _bracket(color, size, thickness, false, false)),
    ];
  }

  Widget _bracket(
      Color color, double size, double thick, bool top, bool left) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
            color: color, thick: thick, top: top, left: left),
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = _recognized
        ? const [
            'Vehicle plate recognized successfully',
            'Gate is opening now',
            'Proceed to your assigned spot',
          ]
        : const [
            'Stop your vehicle at the marked line',
            'Wait for the camera to scan your plate',
            'Gate will open automatically after recognition',
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructions',
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            SizedBox(height: 10),
            for (int i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(steps[i],
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4)),
                  ),
                ],
              ),
              if (i < steps.length - 1) SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;

  _CornerPainter(
      {required this.color,
      required this.thick,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
