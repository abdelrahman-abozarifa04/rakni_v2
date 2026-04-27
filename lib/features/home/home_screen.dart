import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/curent_location_icon.svg',
              height: 20,
              colorFilter: const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            const Text(
              'Current Location',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.white, size: 20),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Handle search action
            },
            icon: SvgPicture.asset(
              'assets/images/search_Icon.svg',
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hello, John!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find the best parking near you',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 32),
              _buildSectionTitle('Near You', onSeeAll: () {}),
              const SizedBox(height: 16),
              _buildMapPlaceholder(),
              const SizedBox(height: 32),
              _buildSectionTitle('Recent Bookings', onSeeAll: () {}),
              const SizedBox(height: 16),
              _buildRecentBookingsList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldStroke),
      ),
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
    );
  }

  Widget _buildSectionTitle(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See All',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated map background (could be an image or interactive map)
          Opacity(
            opacity: 0.1,
            child: SvgPicture.asset(
              'assets/images/map_Icon.svg',
              height: 100,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/Map_mark.svg',
                height: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                'View Map',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsList() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildBookingCard(
            title: 'Mall of Arabia',
            date: 'Today, 10:00 AM',
            imagePath: 'assets/images/Image (Mall of Arabia).svg',
          ),
          const SizedBox(width: 16),
          _buildBookingCard(
            title: 'Cairo Festival City',
            date: 'Yesterday, 6:30 PM',
            imagePath: 'assets/images/Image (Cairo Festival City Mall).svg',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({required String title, required String date, required String imagePath}) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SvgPicture.asset(
                imagePath,
                fit: BoxFit.cover,
                // In case the SVG doesn't load or isn't a proper image
                placeholderBuilder: (context) => Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.image, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
