import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/widgets/egyptian_license_plate.dart';
import 'final_payment_details_screen.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';

class GateExitScanScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final VehicleModel vehicle;
  final double elapsedCost;

  const GateExitScanScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.vehicle,
    required this.elapsedCost,
  });

  @override
  State<GateExitScanScreen> createState() => _GateExitScanScreenState();
}

class _GateExitScanScreenState extends State<GateExitScanScreen>
    with TickerProviderStateMixin {
  bool _recognized = false;
  bool _navigating = false;
  bool _isPolling = false;
  double _exitCost = 0.0;
  bool _showWarning = false;
  Timer? _warningTimer;

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnim;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _exitCost = widget.elapsedCost;

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _warningTimer?.cancel();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    while (_isPolling && mounted && !_recognized) {
      try {
        final data = await ParkingHardwareApiService.instance.fetchLastExit();
        if (data != null && data['success'] == true) {
          final apiPlate = data['plate'] as String?;
          if (apiPlate != null) {
            if (ParkingHardwareApiService.instance.platesMatch(apiPlate, widget.vehicle.plateNumber)) {
              final apiCost = double.tryParse(data['total_cost']?.toString() ?? '');
              _onPlateRecognized(apiCost);
              break;
            } else {
              _triggerWarning();
            }
          }
        }
      } catch (e) {
        debugPrint('Error polling exit: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void _triggerWarning() {
    if (!mounted) return;
    setState(() {
      _showWarning = true;
    });
    _warningTimer?.cancel();
    _warningTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showWarning = false;
        });
      }
    });
  }

  void _onPlateRecognized(double? apiCost) {
    if (!mounted) return;
    setState(() {
      _recognized = true;
      if (apiCost != null) {
        _exitCost = apiCost;
      }
    });
    _scanLineController.stop();
    // Auto-advance to payment after 3 more seconds
    Future.delayed(const Duration(seconds: 3), _advanceToPayment);
  }

  void _stopPolling() {
    _isPolling = false;
  }

  void _advanceToPayment() {
    if (!mounted || _navigating) return;
    _navigating = true;

    final exitTime = DateTime.now();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FinalPaymentDetailsScreen(
          booking: widget.booking,
          parkingLot: widget.parkingLot,
          vehicle: widget.vehicle,
          exitTime: exitTime,
          totalCost: _exitCost,
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
            // "Ending Your Session" header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Ending Your Session ...',
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your parking session will continue until\nsuccessful recognition & payment',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
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
                                        color: AppColors.secondary,
                                        size: 20),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'EXIT SCAN',
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
                      SizedBox(height: 14),
                      // Status
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _recognized
                            ? Column(
                                key: const ValueKey('recognized'),
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Plate Recognized',
                                        style: TextStyle(
                                            color: Colors.green.shade300,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fee: EGP ${_exitCost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 12),
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
                      SizedBox(height: 14),
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
                          onPressed: _advanceToPayment,
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
    return GestureDetector(
      onTap: _triggerWarning,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/Gemini_Generated_Image_isni0bisni0bisni.png'),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.secondary, width: 2),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Text('PLATE',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
              ),
            ),
            ..._buildCornerBrackets(AppColors.secondary),
            Positioned(
              top: 10,
              left: 10,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.green),
                  ),
                  const SizedBox(width: 6),
                  Text('ANPR System enabled',
                      style: TextStyle(color: AppColors.white, fontSize: 11)),
                ],
              ),
            ),
            // Warning Alert
            if (_showWarning)
              Positioned(
                top: 35,
                left: 10,
                right: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showWarning ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You must be standing directly in front of the gate to proceed. Plate not recognized yet.",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (ctx, _) => Positioned(
                top: _scanLineAnim.value *
                    (MediaQuery.of(ctx).size.width * 0.65),
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
              ),
            ),
          ],
        ),
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
              image: const DecorationImage(
                image: AssetImage('assets/images/Gemini_Generated_Image_isni0bisni0bisni.png'),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
            child: Center(
              child: EgyptianLicensePlate(
                plateNumber: widget.vehicle.plateNumber,
              ),
            ),
          ),
          ..._buildCornerBrackets(Colors.green),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
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
          top: 12, left: 12, child: _bracket(color, size, thickness, true, true)),
      Positioned(
          top: 12, right: 12, child: _bracket(color, size, thickness, true, false)),
      Positioned(
          bottom: 12, left: 12, child: _bracket(color, size, thickness, false, true)),
      Positioned(
          bottom: 12, right: 12, child: _bracket(color, size, thickness, false, false)),
    ];
  }

  Widget _bracket(Color color, double size, double thick, bool top, bool left) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, thick: thick, top: top, left: left),
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = _recognized
        ? const [
            'Plate recognized — calculating fee',
            'Proceeding to payment',
            'Gate will open after payment confirmation',
          ]
        : const [
            'Stop your vehicle at the marked line to scan your plate',
            'System will calculate your parking fee',
            'Gate will open automatically after successful payment',
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
