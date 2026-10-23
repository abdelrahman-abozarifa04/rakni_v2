import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/favorites_service.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
import 'package:rakni_v2/core/widgets/maps_ready.dart';
import 'package:rakni_v2/features/booking/booking_details_screen.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';

class ParkingLotDetailScreen extends StatefulWidget {
  final String id, name, address, pricePerHour, imagePath;
  final int availableSlots, totalSlots;
  final double latitude, longitude;
  const ParkingLotDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.address,
    required this.availableSlots,
    required this.totalSlots,
    required this.pricePerHour,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
  });
  @override
  State<ParkingLotDetailScreen> createState() => _State();
}

class _State extends State<ParkingLotDetailScreen> {
  bool _fav = false;
  String _slot = 'Regular';
  int? _apiAvailableSlots;
  Timer? _apiPollTimer;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
    _load();
    _startApiPolling();
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    _apiPollTimer?.cancel();
    super.dispose();
  }

  void _startApiPolling() {
    _pollApiAvailableSlots();
    _apiPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollApiAvailableSlots();
    });
  }

  Future<void> _pollApiAvailableSlots() async {
    try {
      final slots = await ParkingHardwareApiService.instance.fetchSlots();
      final count = slots.where((s) => s.isAvailable).length;
      if (mounted) {
        setState(() {
          _apiAvailableSlots = count;
        });
      }
    } catch (e) {
      debugPrint('[ParkingLotDetailScreen] Error polling API slots: $e');
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final f = await FavoritesService.instance.isFavorite(widget.name);
      if (mounted) setState(() => _fav = f);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    try {
      await FavoritesService.instance.toggleFavorite(widget.name);
      if (mounted) setState(() => _fav = !_fav);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bot = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _hero(top)),
                SliverToBoxAdapter(child: _info()),
                SliverToBoxAdapter(child: _slots()),
                SliverToBoxAdapter(child: _map()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          _book(bot),
        ],
      ),
    );
  }

  Widget _hero(double t) => SizedBox(
    height: 240,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: Colors.grey[800]),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        Positioned(
          top: t + 8,
          left: 16,
          child: _cb(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: t + 8,
          right: 16,
          child: _cb(
            _fav ? Icons.favorite : Icons.favorite_border,
            _toggle,
            c: _fav ? AppColors.secondary : AppColors.white,
          ),
        ),
      ],
    ),
  );
  Widget _cb(IconData i, VoidCallback f, {Color? c}) {
    final iconColor = c ?? AppColors.white;
    return GestureDetector(
      onTap: f,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(i, color: iconColor, size: 20),
      ),
    );
  }

  Widget _info() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.name,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 16,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.address,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hintColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '234 reviews',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _sc(
              Icons.local_parking,
              '${_apiAvailableSlots ?? widget.availableSlots}/${widget.totalSlots}',
              'Available',
            ),
            SizedBox(width: 10),
            _sc(Icons.attach_money, widget.pricePerHour, 'Price'),
            SizedBox(width: 10),
            _sc(Icons.access_time, '24/7', 'Hours'),
          ],
        ),
      ],
    ),
  );

  Widget _sc(IconData i, String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        children: [
          Icon(i, color: AppColors.secondary, size: 20),
          SizedBox(height: 6),
          Text(
            v,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            l,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _slots() {
    const m = {
      'Regular': Icons.directions_car,
      'EV': Icons.electric_car,
      'Disabled': Icons.accessible,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Slot Type',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: m.entries.map((e) {
              final s = _slot == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _slot = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: s
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : AppColors.fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: s ? AppColors.secondary : AppColors.fieldStroke,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e.value,
                          size: 18,
                          color: s ? AppColors.secondary : AppColors.hintColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          e.key,
                          style: TextStyle(
                            color: s
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _map() {
    final p = LatLng(widget.latitude, widget.longitude);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: AbsorbPointer(
            child: MapsReady(child: GoogleMap(
              initialCameraPosition: CameraPosition(target: p, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('lot'),
                  position: p,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: true,
              style: ThemeService.instance.isDark ? _darkMapStyle : _lightMapStyle,
            )),
          ),
        ),
      ),
    );
  }

  Widget _book(double b) => Container(
    padding: EdgeInsets.fromLTRB(20, 12, 20, b + 12),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border(top: BorderSide(color: AppColors.fieldStroke)),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          final cleanPrice = widget.pricePerHour.replaceAll(RegExp(r'[^0-9.]'), '');
          final price = double.tryParse(cleanPrice) ?? 7.0;
          final lot = ParkingLotModel(
            id: widget.id,
            name: widget.name,
            address: widget.address,
            latitude: widget.latitude,
            longitude: widget.longitude,
            totalSlots: widget.totalSlots,
            availableSlots: _apiAvailableSlots ?? widget.availableSlots,
            pricePerHour: price,
            imageUrl: widget.imagePath,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(parkingLot: lot),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Book Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Dark-mode map style JSON
// ─────────────────────────────────────────────────────────────────
const String _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#2A2A2B"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#99A1AF"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1A1A1B"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2A2A2B"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#232B23"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#232B23"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6A7282"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#232B23"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3D434C"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212326"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#99A1AF"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#48505C"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#B0B8C4"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#6A7282"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1A1F2E"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4B5B8B"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64748B"}]}
]''';

// ─────────────────────────────────────────────────────────────────
// Light-mode map style JSON
// ─────────────────────────────────────────────────────────────────
const String _lightMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#F6F7F4"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4A5568"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#EAECEE"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#D8EDCD"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#D8EDCD"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#718096"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#BEDFB3"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#D1D5DB"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#4A5568"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#F7FAFC"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#2D3748"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#718096"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#BEE3F8"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2B6CB0"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#718096"}]}
]''';
