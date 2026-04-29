import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/location_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildTopBar(context),
            ),

            // ── Search Bar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildSearchBar(),
              ),
            ),

            // ── Section: Nearby Parking ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _buildSectionHeader('Nearby Parking', 'See all'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _NearbyParkingCard(
                      name: 'Mall of Arabia',
                      distance: '0.8 km',
                      available: 42,
                      price: 'EGP 10/hr',
                      imagePath: 'assets/images/mall_of_arabia.png',
                    ),
                    SizedBox(width: 14),
                    _NearbyParkingCard(
                      name: 'Cairo Festival City',
                      distance: '2.1 km',
                      available: 18,
                      price: 'EGP 15/hr',
                      imagePath: 'assets/images/cfc_mall.png',
                    ),
                    SizedBox(width: 14),
                    _NearbyParkingCard(
                      name: 'City Stars',
                      distance: '3.5 km',
                      available: 76,
                      price: 'EGP 8/hr',
                      imagePath: 'assets/images/mall_of_arabia.png',
                    ),
                  ],
                ),
              ),
            ),

            // ── Section: Quick Actions ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                child: _buildSectionHeader('Quick Actions', ''),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    _QuickAction(
                      svgPath: 'assets/images/Map_mark.svg',
                      label: 'Find\nParking',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/booking_Icon.svg',
                      label: 'Reserve\nSpot',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/makefavorate_Icon.svg',
                      label: 'Favourites',
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/hour_Icon.svg',
                      label: 'History',
                    ),
                  ],
                ),
              ),
            ),

            // ── Section: My Active Session ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _buildSectionHeader('Active Session', ''),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _ActiveSessionCard(),
              ),
            ),

            // ── Section: Featured Malls ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _buildSectionHeader('Featured Malls', 'See all'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: const [
                    _FeaturedMallTile(
                      name: 'Mall of Arabia',
                      address: '6th of October, Giza',
                      slots: '42 spots available',
                      imagePath: 'assets/images/mall_of_arabia.png',
                      isFavorite: true,
                    ),
                    SizedBox(height: 12),
                    _FeaturedMallTile(
                      name: 'Cairo Festival City Mall',
                      address: 'New Cairo, Cairo',
                      slots: '18 spots available',
                      imagePath: 'assets/images/cfc_mall.png',
                      isFavorite: false,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationScreen()),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/curent_location_icon.svg',
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        AppColors.secondary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'New Cairo, Cairo',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.fieldColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.fieldStroke),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset(
            'assets/images/search_Icon.png',
            height: 18,
            color: AppColors.hintColor,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.search, color: AppColors.hintColor),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search for a parking spot...',
              style: TextStyle(color: AppColors.hintColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _NearbyParkingCard extends StatelessWidget {
  final String name;
  final String distance;
  final int available;
  final String price;
  final String imagePath;

  const _NearbyParkingCard({
    required this.name,
    required this.distance,
    required this.available,
    required this.price,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$available free',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/location_Icon.svg',
                      height: 11,
                      colorFilter: const ColorFilter.mode(
                          AppColors.textSecondary, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      'assets/images/hour_Icon.svg',
                      height: 11,
                      colorFilter: const ColorFilter.mode(
                          AppColors.secondary, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

class _QuickAction extends StatelessWidget {
  final String svgPath;
  final String label;

  const _QuickAction({required this.svgPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 26,
              colorFilter:
              const ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.fieldColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/Map_mark.svg',
                height: 22,
                colorFilter: const ColorFilter.mode(
                    AppColors.secondary, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mall of Arabia – P2',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Started 42 min ago  ·  EGP 7.00',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'End',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedMallTile extends StatelessWidget {
  final String name;
  final String address;
  final String slots;
  final String imagePath;
  final bool isFavorite;

  const _FeaturedMallTile({
    required this.name,
    required this.address,
    required this.slots,
    required this.imagePath,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white12)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/images/makefavorate_Icon.svg',
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          isFavorite
                              ? AppColors.secondary
                              : AppColors.hintColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/location_Icon.svg',
                        height: 12,
                        colorFilter: const ColorFilter.mode(
                            AppColors.textSecondary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slots,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}