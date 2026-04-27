import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E1E1E), // Slightly different shade for map
              child: Opacity(
                opacity: 0.1,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/map_Icon.svg',
                    height: 200,
                    colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
          
          // Simulated Map Markers
          Positioned(
            top: 300,
            left: 100,
            child: SvgPicture.asset(
              'assets/images/Map_mark.svg',
              height: 40,
            ),
          ),
          Positioned(
            top: 400,
            right: 120,
            child: SvgPicture.asset(
              'assets/images/Map_mark.svg',
              height: 48, // A bit larger to simulate being selected
            ),
          ),
          Positioned(
            top: 250,
            right: 80,
            child: SvgPicture.asset(
              'assets/images/Map_mark.svg',
              height: 40,
            ),
          ),

          // Top Bar (Search + Filter)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.fieldColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.fieldStroke),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/search_Icon.svg',
                            height: 20,
                            colorFilter: const ColorFilter.mode(AppColors.hintColor, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Search by address or place',
                            style: TextStyle(
                              color: AppColors.hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location FAB
          Positioned(
            bottom: 230,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/curent_location_icon.svg',
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
                ),
              ),
            ),
          ),

          // Bottom Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fieldStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Rakni Parking',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.5',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '6th of October',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.route, '2 km'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.access_time, '10 mins'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Details',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
