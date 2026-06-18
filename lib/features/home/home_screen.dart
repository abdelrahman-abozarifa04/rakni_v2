import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/services/geocoding_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rakni_v2/core/services/favorites_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/bookings/bookings_screen.dart';
import 'package:rakni_v2/features/home/favourites_screen.dart';
import 'package:rakni_v2/features/home/location_screen.dart';
import 'package:rakni_v2/features/home/parking_lot_detail_screen.dart';
import 'package:rakni_v2/features/home/filter_bottom_sheet.dart';
import 'package:rakni_v2/features/home/parking_search_screen.dart';
import 'package:rakni_v2/features/main/main_shell.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rakni_v2/core/services/booking_service.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/repositories/parking_lot_repository.dart';
import 'package:rakni_v2/features/booking/active_session_screen.dart';
import 'package:rakni_v2/features/notifications/notifications_screen.dart';
import 'package:rakni_v2/core/models/notification_model.dart';
import 'package:rakni_v2/core/services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _locationText = 'Getting location...';
  bool _locationLoading = true;
  FilterConfig? _activeFilter;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    if (mounted) {
      setState(() {
        _locationLoading = true;
        _locationText = 'Getting location...';
      });
    }

    try {
      // Geolocator works on web through the browser Geolocation API. It needs
      // HTTPS in production, while localhost is allowed during development.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocation('Location disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setLocation('Location permission needed');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocation('Enable location in settings');
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () async {
              final lastKnown = await Geolocator.getLastKnownPosition();
              if (lastKnown != null) return lastKnown;
              return Position(
                longitude: 31.2357,
                latitude: 30.0444,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            },
          );

      final locationName = await GeocodingService.instance.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      _setLocation(locationName);
    } catch (_) {
      _setLocation('Cairo, Egypt');
    }
  }

  void _setLocation(String value) {
    if (!mounted) return;
    setState(() {
      _locationText = value;
      _locationLoading = false;
    });
  }



  Future<void> _selectLocation() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationScreen()),
    );
    if (selected != null && selected.trim().isNotEmpty && mounted) {
      setState(() {
        _locationText = selected;
        _locationLoading = false;
      });
    }
  }

  void _openDetail(ParkingLotModel lot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingLotDetailScreen(
          id: lot.id,
          name: lot.name,
          address: lot.address,
          availableSlots: lot.availableSlots,
          totalSlots: lot.totalSlots,
          pricePerHour: 'EGP ${lot.pricePerHour.toStringAsFixed(0)}/hr',
          imagePath: lot.imageUrl ?? 'assets/images/mall_of_arabia.png',
          latitude: lot.latitude,
          longitude: lot.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildSearchBar(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _buildSectionHeader('Nearby Parking', 'See all'),
              ),
            ),
            // ── Nearby Parking — real-time from Firestore ──────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: StreamBuilder<List<ParkingLotModel>>(
                  stream:
                      ParkingLotRepository.instance.streamAvailableLots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      );
                    }
                    final lots = snapshot.data ?? [];
                    final filtered = _activeFilter != null
                        ? lots
                            .where((l) =>
                                _activeFilter!.matchesPrice(l.pricePerHour))
                            .toList()
                        : lots;
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No parking lots available',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final lot = filtered[i];
                        return GestureDetector(
                          onTap: () => _openDetail(lot),
                          child: _NearbyParkingCard(
                            name: lot.name,
                            distance: '—',
                            available: lot.availableSlots,
                            price:
                                'EGP ${lot.pricePerHour.toStringAsFixed(0)}/hr',
                            imagePath: lot.imageUrl ??
                                'assets/images/mall_of_arabia.png',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
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
                  children: [
                    _QuickAction(
                      svgPath: 'assets/images/Map_mark.svg',
                      label: 'Find\nParking',
                      onTap: () {
                        final mainShellState =
                            context.findAncestorStateOfType<MainShellState>();
                        if (mainShellState != null) {
                          mainShellState.setTab(1);
                        }
                      },
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/booking_Icon.svg',
                      label: 'Reserve\nSpot',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParkingSearchScreen(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/makefavorate_Icon.svg',
                      label: 'Favourites',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavouritesScreen(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    _QuickAction(
                      svgPath: 'assets/images/hour_Icon.svg',
                      label: 'History',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<BookingModel?>(
              stream: BookingService.instance.streamActiveBooking(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                final activeBooking = snapshot.data;
                if (activeBooking == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: _buildSectionHeader('Active Session', ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ActiveSessionCard(booking: activeBooking),
                      ),
                    ],
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _buildSectionHeader('Featured Malls', 'See all'),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _FeaturedMallTile(
                      name: 'Mall of Arabia',
                      address: '6th of October, Giza',
                      slots: '42 spots available',
                      imagePath: 'assets/images/mall_of_arabia.png',
                    ),
                    SizedBox(height: 12),
                    _FeaturedMallTile(
                      name: 'Cairo Festival City Mall',
                      address: 'New Cairo, Cairo',
                      slots: '18 spots available',
                      imagePath: 'assets/images/cfc_mall.png',
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
              onTap: _selectLocation,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/curent_location_icon.svg',
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      AppColors.secondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 6),
                  if (_locationLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                  if (_locationLoading) SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _locationText,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          // ── Theme toggle ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => ThemeService.instance.toggle(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: Icon(
                ThemeService.instance.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
          // ── Notification bell ─────────────────────────────────────────────
          StreamBuilder<List<NotificationModel>?>(
            stream: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return Stream<List<NotificationModel>?>.value(null);
              }
              return FirestoreService.instance
                  .streamNotifications(uid)
                  .map<List<NotificationModel>?>((list) => list);
            }(),
            builder: (ctx, snap) {
              final unreadCount = snap.data
                  ?.where((n) => !n.isRead)
                  .length ?? 0;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.fieldColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.fieldStroke),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParkingSearchScreen()),
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldStroke),
        ),
        child: Row(
          children: [
            SizedBox(width: 14),
            Icon(Icons.search, color: AppColors.hintColor, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search for a parking spot...',
                style: TextStyle(color: AppColors.hintColor, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await FilterBottomSheet.show(context);
                if (result != null && mounted) {
                  setState(() => _activeFilter = result);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _activeFilter != null
                      ? AppColors.secondary
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _activeFilter != null
                      ? AppColors.black
                      : AppColors.black,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: TextStyle(
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white24,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$available free',
                      style: TextStyle(
                        color: AppColors.black,
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
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/location_Icon.svg',
                      height: 11,
                      colorFilter: ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      distance,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      'assets/images/hour_Icon.svg',
                      height: 11,
                      colorFilter: ColorFilter.mode(
                        AppColors.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      price,
                      style: TextStyle(
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
  final VoidCallback? onTap;

  const _QuickAction({required this.svgPath, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.fieldColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.fieldStroke),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                svgPath,
                height: 26,
                colorFilter: ColorFilter.mode(
                  AppColors.secondary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatefulWidget {
  final BookingModel booking;
  const _ActiveSessionCard({required this.booking});

  @override
  State<_ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<_ActiveSessionCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _calculateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateElapsed();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateElapsed() {
    _elapsed = DateTime.now().difference(widget.booking.startTime);
    if (_elapsed.isNegative) _elapsed = Duration.zero;
  }

  double get _currentCost {
    final hours = _elapsed.inSeconds / 3600.0;
    return hours * widget.booking.pricePerHour;
  }

  Future<void> _navigateToActiveSession() async {
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
      final lot = await FirestoreService.instance.getParkingLot(widget.booking.parkingLotId);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final vehicles = await FirestoreService.instance.streamVehicles(uid).first;
      final vehicle = vehicles.firstWhere(
        (v) => v.id == widget.booking.vehicleId,
        orElse: () => vehicles.isNotEmpty 
            ? vehicles.first 
            : VehicleModel(
                id: widget.booking.vehicleId,
                brand: 'Vehicle',
                model: '',
                plateNumber: widget.booking.vehiclePlate,
                color: '',
                isDefault: false,
              ),
      );

      if (mounted && context.mounted) {
        Navigator.pop(context); // Dismiss loading overlay
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveSessionScreen(
              booking: widget.booking,
              parkingLot: lot ?? ParkingLotModel(
                id: widget.booking.parkingLotId,
                name: widget.booking.lotName,
                address: widget.booking.lotAddress,
                latitude: 0,
                longitude: 0,
                totalSlots: 0,
                availableSlots: 0,
                pricePerHour: widget.booking.pricePerHour,
              ),
              vehicle: vehicle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final elapsedMinutes = _elapsed.inMinutes;
    String subtitle;
    if (_elapsed.inHours > 0) {
      subtitle = 'Started ${_elapsed.inHours}h ${(_elapsed.inMinutes % 60)}m ago  •  EGP ${_currentCost.toStringAsFixed(2)}';
    } else {
      subtitle = 'Started $elapsedMinutes min ago  •  EGP ${_currentCost.toStringAsFixed(2)}';
    }

    String displayName = widget.booking.lotName.isNotEmpty 
        ? widget.booking.lotName 
        : 'Parking Session';
    if (widget.booking.spotLabel.isNotEmpty) {
      displayName += ' - ${widget.booking.spotLabel}';
    }

    return GestureDetector(
      onTap: _navigateToActiveSession,
      child: Container(
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
                  colorFilter: ColorFilter.mode(
                    AppColors.secondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _navigateToActiveSession,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'End',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMallTile extends StatefulWidget {
  final String name;
  final String address;
  final String slots;
  final String imagePath;

  const _FeaturedMallTile({
    required this.name,
    required this.address,
    required this.slots,
    required this.imagePath,
  });

  @override
  State<_FeaturedMallTile> createState() => _FeaturedMallTileState();
}

class _FeaturedMallTileState extends State<_FeaturedMallTile> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final favorite = await FavoritesService.instance.isFavorite(widget.name);
      if (mounted) setState(() => _isFavorite = favorite);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      await FavoritesService.instance.toggleFavorite(widget.name);
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
  }

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
              widget.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                child: Icon(Icons.broken_image, color: Colors.white12),
              ),
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
                          widget.name,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFavorite,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite
                                ? AppColors.secondary
                                : AppColors.hintColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/location_Icon.svg',
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.slots,
                      style: TextStyle(
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
