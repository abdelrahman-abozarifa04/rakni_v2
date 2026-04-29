import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/bookings/booking_details_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildBookingCard(
                      context: context,
                      title: 'Downtown Parking',
                      address: '123 Main St, City Center',
                      date: 'Apr 25, 2026',
                      time: '09:00 AM - 05:00 PM',
                      vehicle: 'Toyota Camry - ABC 1234',
                      total: '\$40',
                      status: 'Active',
                    ),
                    const SizedBox(height: 16),
                    _buildBookingCard(
                      context: context,
                      title: 'Mall Parking Garage',
                      address: '456 Shopping Blvd',
                      date: 'Apr 20, 2026',
                      time: '02:00 PM - 06:00 PM',
                      vehicle: 'Toyota Camry - ABC 1234',
                      total: '\$12',
                      status: 'Completed',
                    ),
                    const SizedBox(height: 16),
                    _buildBookingCard(
                      context: context,
                      title: 'Mall Parking Garage',
                      address: '456 Shopping Blvd',
                      date: 'Apr 18, 2026',
                      time: '10:00 AM - 01:00 PM',
                      vehicle: 'Toyota Camry - ABC 1234',
                      total: '\$8',
                      status: 'Completed',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required String title,
    required String address,
    required String date,
    required String time,
    required String vehicle,
    required String total,
    required String status,
  }) {
    final isActive = status == 'Active';
    final badgeColor = isActive
        ? AppColors.secondary
        : AppColors.textSecondary.withValues(alpha: 0.3);
    final badgeTextColor = isActive ? Colors.black : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(
              title: title,
              address: address,
              date: date,
              time: time,
              vehicle: vehicle,
              total: total,
              status: status,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
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
                  _buildInfoRow(Icons.location_on_outlined, address),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_outlined, date),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time_outlined, time),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.directions_car_outlined, vehicle),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.textSecondary, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        total,
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
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailsScreen(
                                title: title,
                                address: address,
                                date: date,
                                time: time,
                                vehicle: vehicle,
                                total: total,
                                status: status,
                              ),
                            ),
                          );
                        },
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
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Cancel action
                        },
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
            ]
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
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
