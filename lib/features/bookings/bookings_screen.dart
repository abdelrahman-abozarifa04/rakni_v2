import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/booking_service.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/features/booking/active_session_screen.dart';
import 'package:rakni_v2/features/bookings/booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _firestoreService = FirestoreService.instance;
  bool _isProcessing = false;

  Future<void> _navigateToActiveSession(BuildContext context, BookingModel booking) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    try {
      final lot = await _firestoreService.getParkingLot(booking.parkingLotId);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final vehicles = await _firestoreService.streamVehicles(uid).first;
      final vehicle = vehicles.firstWhere(
        (v) => v.id == booking.vehicleId,
        orElse: () => vehicles.isNotEmpty 
            ? vehicles.first 
            : VehicleModel(
                id: booking.vehicleId,
                brand: 'Vehicle',
                model: '',
                plateNumber: booking.vehiclePlate,
                color: '',
                isDefault: false,
              ),
      );

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveSessionScreen(
              booking: booking,
              parkingLot: lot ?? ParkingLotModel(
                id: booking.parkingLotId,
                name: booking.lotName,
                address: booking.lotAddress,
                latitude: 0,
                longitude: 0,
                totalSlots: 0,
                availableSlots: 0,
                pricePerHour: booking.pricePerHour,
              ),
              vehicle: vehicle,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load session: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelBooking(BuildContext context, BookingModel booking) async {
    if (_isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Booking', style: TextStyle(color: AppColors.white)),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    try {
      await BookingService.instance.cancelBooking(
        bookingId: booking.id,
        lotId: booking.parkingLotId,
        slotId: booking.slotId,
      );

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Your Bookings',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View and manage your parking reservations',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: uid.isEmpty
                    ? _buildEmptyState('Please log in to view your bookings.')
                    : StreamBuilder<List<BookingModel>>(
                        stream: _firestoreService.streamUserBookings(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.secondary),
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildErrorState('Error: ${snapshot.error}');
                          }

                          final bookings = snapshot.data ?? [];
                          if (bookings.isEmpty) {
                            return _buildEmptyState('You have no bookings yet.');
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: bookings.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildBookingCard(context, bookings[index]);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.hintColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final statusLower = booking.status.toLowerCase();
    final isActive = statusLower == 'active';
    final isPending = statusLower == 'pending';
    final isCompleted = statusLower == 'completed';

    Color badgeColor;
    Color badgeTextColor;
    String statusText;

    if (isActive) {
      badgeColor = AppColors.secondary;
      badgeTextColor = Colors.black;
      statusText = 'Active';
    } else if (isPending) {
      badgeColor = Colors.orange.withValues(alpha: 0.15);
      badgeTextColor = Colors.orange;
      statusText = 'Pending';
    } else if (isCompleted) {
      badgeColor = AppColors.textSecondary.withValues(alpha: 0.3);
      badgeTextColor = AppColors.textSecondary;
      statusText = 'Completed';
    } else {
      badgeColor = AppColors.error.withValues(alpha: 0.15);
      badgeTextColor = AppColors.error;
      statusText = 'Cancelled';
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    String dateStr;
    try {
      dateStr = "${months[booking.startTime.month - 1]} ${booking.startTime.day}, ${booking.startTime.year}";
    } catch (_) {
      dateStr = 'Unknown Date';
    }

    String _formatTimeOfDay(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${hour.toString().padLeft(2, '0')}:$min $ampm';
    }

    final timeStr = booking.endTime != null 
        ? "${_formatTimeOfDay(booking.startTime)} - ${_formatTimeOfDay(booking.endTime!)}"
        : "${_formatTimeOfDay(booking.startTime)} - Ongoing";

    return GestureDetector(
      onTap: () {
        if (isActive) {
          _navigateToActiveSession(context, booking);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(
                booking: booking,
                onCancel: () async {
                  await _cancelBooking(context, booking);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.secondary.withValues(alpha: 0.3) : Colors.transparent,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.lotName.isNotEmpty ? booking.lotName : 'Parking Lot',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, booking.lotAddress.isNotEmpty ? booking.lotAddress : 'Cairo, Egypt'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_outlined, dateStr),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time_outlined, timeStr),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.directions_car_outlined, booking.vehiclePlate.isNotEmpty ? booking.vehiclePlate : 'No Plate'),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.fieldStroke, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                      Text(
                        'EGP ${booking.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.fieldStroke,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToActiveSession(context, booking),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'View Details',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: AppColors.fieldStroke,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _cancelBooking(context, booking),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
