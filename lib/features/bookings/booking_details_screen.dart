import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/models/booking_model.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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

    String formatTimeOfDay(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${hour.toString().padLeft(2, '0')}:$min $ampm';
    }

    final timeStr = booking.endTime != null 
        ? "${formatTimeOfDay(booking.startTime)} - ${formatTimeOfDay(booking.endTime!)}"
        : "${formatTimeOfDay(booking.startTime)} - Ongoing";

    final title = booking.lotName.isNotEmpty ? booking.lotName : 'Parking Lot';
    final address = booking.lotAddress.isNotEmpty ? booking.lotAddress : 'Cairo, Egypt';
    final vehicle = booking.vehiclePlate.isNotEmpty ? booking.vehiclePlate : 'No Plate';
    final total = 'EGP ${booking.totalAmount.toStringAsFixed(0)}';
    
    // User-friendly payment method
    String paymentMethodStr = 'Wallet';
    if (booking.paymentMethod.toLowerCase() == 'visa') {
      paymentMethodStr = 'Visa ending in 1234';
    } else if (booking.paymentMethod.isNotEmpty) {
      paymentMethodStr = booking.paymentMethod[0].toUpperCase() + booking.paymentMethod.substring(1);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Booking Details',
            style:
                TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Map placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child:
                    Icon(Icons.map, size: 48, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(height: 24),
            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(color: AppColors.textSecondary, height: 1),
                  SizedBox(height: 20),
                  _buildDetailRow('Date', dateStr),
                  SizedBox(height: 16),
                  _buildDetailRow('Time', timeStr),
                  SizedBox(height: 16),
                  _buildDetailRow('Vehicle', vehicle),
                  SizedBox(height: 16),
                  _buildDetailRow('Payment Method', paymentMethodStr),
                  SizedBox(height: 20),
                  Divider(color: AppColors.textSecondary, height: 1),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        total,
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            if (isActive || isPending) ...[
              // QR Code placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scan to enter',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    QrImageView(
                      data: 'RAKNI-BOOKING-${booking.id}',
                      version: QrVersions.auto,
                      size: 200,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      backgroundColor: AppColors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Reservation #${booking.reservationId}',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel Booking',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 24),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
