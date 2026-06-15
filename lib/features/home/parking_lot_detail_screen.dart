import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/services/favorites_service.dart';
import 'package:rakni_v2/features/booking/booking_details_screen.dart';

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
  @override
  void initState() {
    super.initState();
    _load();
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
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
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
  Widget _cb(IconData i, VoidCallback f, {Color c = AppColors.white}) =>
      GestureDetector(
        onTap: f,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(i, color: c, size: 20),
        ),
      );

  Widget _info() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.name,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.address,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            const Text(
              '4.8',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.hintColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '234 reviews',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _sc(
              Icons.local_parking,
              '${widget.availableSlots}/${widget.totalSlots}',
              'Available',
            ),
            const SizedBox(width: 10),
            _sc(Icons.attach_money, widget.pricePerHour, 'Price'),
            const SizedBox(width: 10),
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
          const SizedBox(height: 6),
          Text(
            v,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l,
            style: const TextStyle(
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
          const Text(
            'Slot Type',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
                        const SizedBox(width: 6),
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
            child: GoogleMap(
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
            ),
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
            availableSlots: widget.availableSlots,
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
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Book Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
