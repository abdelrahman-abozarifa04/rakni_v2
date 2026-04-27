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
          // Simulated map background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Opacity(
                opacity: 0.08,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/map_Icon.svg',
                    height: 300,
                    colorFilter: const ColorFilter.mode(
                        AppColors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),

          // Parking markers
          Positioned(
            top: 280,
            left: 90,
            child: _ParkingMarker(label: 'P1', spots: 42),
          ),
          Positioned(
            top: 360,
            right: 100,
            child: _ParkingMarker(label: 'P2', spots: 18),
          ),
          Positioned(
            top: 180,
            right: 60,
            child: _ParkingMarker(label: 'P3', spots: 76),
          ),

          // Top search area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.fieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.fieldStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      SvgPicture.asset(
                        'assets/images/search_Icon.svg',
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            AppColors.hintColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search for a parking spot...',
                          style: TextStyle(
                              color: AppColors.hintColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Current location FAB
          Positioned(
            bottom: 24,
            right: 20,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/curent_location_icon.svg',
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                        AppColors.primary, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkingMarker extends StatelessWidget {
  final String label;
  final int spots;

  const _ParkingMarker({required this.label, required this.spots});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$spots free',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/images/Map_mark.svg',
          height: 20,
          colorFilter:
              const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
        ),
      ],
    );
  }
}
