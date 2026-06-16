import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'outdoor_navigation_screen.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final ParkingSlotModel slot;
  final VehicleModel vehicle;

  const BookingConfirmedScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.slot,
    required this.vehicle,
  });

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _fadeController;
  late final Animation<double> _checkScale;
  late final Animation<double> _fadeIn;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _checkScale = CurvedAnimation(
        parent: _checkController, curve: Curves.elasticOut);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _checkController
            ..repeat(reverse: true, period: const Duration(seconds: 2)),
          curve: Curves.easeInOut),
    );

    // Stagger the animations
    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300),
        () => mounted ? _fadeController.forward() : null);
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final lot = widget.parkingLot;
    final expiryTime = booking.startTime.add(const Duration(minutes: 30));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Animated checkmark
                _buildCheckmark(),
                const SizedBox(height: 20),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your parking spot has been reserved',
                  style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Booking ID + expiry pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoPill(
                        icon: Icons.confirmation_number_outlined,
                        label: '#${booking.reservationId}',
                        color: AppColors.secondary),
                    const SizedBox(width: 10),
                    _buildInfoPill(
                        icon: Icons.timer_outlined,
                        label: 'Expires ${_formatTime(expiryTime)}',
                        color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                // Location card
                _buildLocationCard(booking),
                const SizedBox(height: 16),
                // Info grid
                Row(
                  children: [
                    Expanded(child: _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: _formatDate(booking.startTime))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInfoCard(
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: '${_formatTime(booking.startTime)} - ${booking.endTime != null ? _formatTime(booking.endTime!) : '--'}')),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                    icon: Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value:
                        '${widget.vehicle.brand} ${widget.vehicle.model} · ${widget.vehicle.plateNumber}'),
                const SizedBox(height: 16),
                // Seamless entry banner
                _buildAnprBanner(),
                const SizedBox(height: 28),
                // Action buttons
                OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (r) => false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppColors.fieldStroke),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(color: AppColors.white, fontSize: 15)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutdoorNavigationScreen(
                        booking: widget.booking,
                        parkingLot: lot,
                        slot: widget.slot,
                        vehicle: widget.vehicle,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Navigate to Parking',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return AnimatedBuilder(
      animation: _checkController,
      builder: (ctx, _) {
        return ScaleTransition(
          scale: _checkScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary
                      .withValues(alpha: 0.12 * _glowAnim.value),
                ),
              ),
              // Inner circle
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black, size: 44),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPill(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_parking, color: AppColors.secondary, size: 16),
              SizedBox(width: 6),
              Text('PARKING LOCATION',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.parkingLot.name,
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(widget.parkingLot.address,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view_rounded,
                    color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${booking.level} · ${booking.spotLabel}',
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
      required String label,
      required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnprBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            Colors.transparent
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors,
                color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seamless Entry Enabled',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 2),
                Text(
                    'Gates will open automatically via AI Plate Recognition',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
