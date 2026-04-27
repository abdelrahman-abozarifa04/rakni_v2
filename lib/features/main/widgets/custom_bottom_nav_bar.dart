import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525), // Adjust based on design
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        items: [
          _buildNavItem(
            icon: 'assets/images/home_Icon.svg',
            label: 'Home',
            isSelected: currentIndex == 0,
          ),
          _buildNavItem(
            icon: 'assets/images/map_Icon.svg',
            label: 'Map',
            isSelected: currentIndex == 1,
          ),
          _buildNavItem(
            icon: 'assets/images/booking_Icon.svg',
            label: 'Booking',
            isSelected: currentIndex == 2,
          ),
          _buildNavItem(
            icon: 'assets/images/profile_Icon.svg',
            label: 'Profile',
            isSelected: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 6.0, top: 8.0),
        child: SvgPicture.asset(
          icon,
          colorFilter: ColorFilter.mode(
            isSelected ? AppColors.secondary : AppColors.textSecondary,
            BlendMode.srcIn,
          ),
          height: 24,
        ),
      ),
      label: label,
    );
  }
}
