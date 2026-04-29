import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// Garage data model
// ─────────────────────────────────────────────────────────────────
class _Garage {
  final String id;
  final String name;
  final LatLng position;
  final int slots;
  const _Garage({
    required this.id,
    required this.name,
    required this.position,
    required this.slots,
  });
}

// ─────────────────────────────────────────────────────────────────
// Hardcoded garages
// ─────────────────────────────────────────────────────────────────
const List<_Garage> _garages = [
  _Garage(id: 'g1', name: 'Mall of Arabia Parking', position: LatLng(30.0131, 31.2089), slots: 42),
  _Garage(id: 'g2', name: 'Cairo Festival City',    position: LatLng(30.0280, 31.4028), slots: 18),
  _Garage(id: 'g3', name: 'Point 90 Mall',          position: LatLng(30.0074, 31.4711), slots: 76),
  _Garage(id: 'g4', name: 'Waterway Parking',       position: LatLng(30.0225, 31.4662), slots: 31),
  _Garage(id: 'g5', name: 'AUC Garage',             position: LatLng(30.0219, 31.4997), slots: 55),
];

// ─────────────────────────────────────────────────────────────────
// API key (same value registered in AndroidManifest / AppDelegate)
// ─────────────────────────────────────────────────────────────────
const _kApiKey = 'AIzaSyCI9YS3MzCZju4NbBKa04NocCG8yA1J-LI';

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
// MapScreen
// ─────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  GoogleMapController? _mapController;

  LatLng? _userPosition;
  bool _locationLoading = true;

  final Map<MarkerId, Marker> _markers = {};
  BitmapDescriptor? _garageIcon;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<PolylineId, Polyline> _polylines = {};
  _Garage? _routeTarget;
  double? _routeDistanceKm;

  // ── lifecycle ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    _rebuildGarageMarkers();
  }

  // ── location ────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _showBar('Location services are disabled.');
        await _rebuildGarageMarkers();
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _showBar('Location permission required.');
        await _rebuildGarageMarkers();
        if (mounted) setState(() => _locationLoading = false);
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _showBar('Location permission permanently denied — enable in Settings.');
        await _rebuildGarageMarkers();
        if (mounted) setState(() => _locationLoading = false);
        return;
      }

      // Use balanced accuracy and timeout to avoid hanging
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10), onTimeout: () => Geolocator.getLastKnownPosition().then((p) => p ?? Position(longitude: 31.4997, latitude: 30.0219, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0)));
      
      if (!mounted) return;
      _userPosition = LatLng(pos.latitude, pos.longitude);

      await _rebuildGarageMarkers();

      final ctrl = await _controllerCompleter.future;
      await ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userPosition!, zoom: 15),
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      _showBar('Using default location (Egypt)');
      await _rebuildGarageMarkers();
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── markers ─────────────────────────────────────────────────────
  Future<void> _rebuildGarageMarkers() async {
    _garageIcon ??= BitmapDescriptor.defaultMarkerWithHue(68);

    final query = _searchQuery;
    final updated = <MarkerId, Marker>{};

    // No longer need to manually keep user marker as we use myLocationEnabled: true

    for (final g in _garages) {
      if (query.isNotEmpty && !g.name.toLowerCase().contains(query)) continue;
      final id = MarkerId(g.id);
      updated[id] = Marker(
        markerId: id,
        position: g.position,
        icon: _garageIcon!,
        infoWindow: InfoWindow(title: g.name, snippet: '${g.slots} spots'),
        onTap: () => _showGarageSheet(g),
      );
    }

    if (mounted) setState(() { _markers ..clear() ..addAll(updated); });
  }

  void _addUserMarker() {
    if (_userPosition == null) return;
    const id = MarkerId('user');
    _markers[id] = Marker(
      markerId: id,
      position: _userPosition!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'You are here'),
    );
    if (mounted) setState(() {});
  }

  // ── garage bottom sheet ─────────────────────────────────────────
  void _showGarageSheet(_Garage garage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GarageSheet(
        garage: garage,
        onGetDirections: () {
          Navigator.pop(context);
          _drawRouteTo(garage);
        },
      ),
    );
  }

  // ── routing ─────────────────────────────────────────────────────
  Future<void> _drawRouteTo(_Garage garage) async {
    if (_userPosition == null) {
      _showBar('User location not available yet.');
      return;
    }

    setState(() { _polylines.clear(); _routeTarget = null; _routeDistanceKm = null; });

    try {
      final pp = PolylinePoints();
      final result = await pp.getRouteBetweenCoordinates(
        googleApiKey: _kApiKey,
        request: PolylineRequest(
          origin: PointLatLng(_userPosition!.latitude, _userPosition!.longitude),
          destination: PointLatLng(garage.position.latitude, garage.position.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) { _showBar('Could not find a route.'); return; }

      final pts = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      const pid = PolylineId('route');
      setState(() {
        _polylines[pid] = Polyline(
          polylineId: pid,
          points: pts,
          color: AppColors.secondary,
          width: 4,
        );
        _routeTarget = garage;
        _routeDistanceKm = _distKm(_userPosition!, garage.position);
      });

      final bounds = _boundsOf([_userPosition!, garage.position]);
      final ctrl = await _controllerCompleter.future;
      await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      _showBar('Route error: $e');
    }
  }

  Future<void> _goToNearest() async {
    if (_userPosition == null) {
      _showBar('Getting your location…');
      await _initLocation();
      return;
    }
    _Garage? nearest;
    double min = double.infinity;
    for (final g in _garages) {
      final d = _distKm(_userPosition!, g.position);
      if (d < min) { min = d; nearest = g; }
    }
    if (nearest != null) await _drawRouteTo(nearest);
  }

  void _clearRoute() => setState(() {
    _polylines.clear(); _routeTarget = null; _routeDistanceKm = null;
  });

  // ── helpers ─────────────────────────────────────────────────────
  double _distKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _rad(double d) => d * math.pi / 180;

  LatLngBounds _boundsOf(List<LatLng> pts) {
    double s = pts.first.latitude, n = pts.first.latitude;
    double w = pts.first.longitude, e = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < s) s = p.latitude;
      if (p.latitude > n) n = p.latitude;
      if (p.longitude < w) w = p.longitude;
      if (p.longitude > e) e = p.longitude;
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  void _showBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.fieldColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(30.0219, 31.4997),
              zoom: 12,
            ),
            style: _darkMapStyle,
            onMapCreated: (ctrl) async {
              _controllerCompleter.complete(ctrl);
              _mapController = ctrl;
              await _rebuildGarageMarkers();
            },
            markers: Set<Marker>.of(_markers.values),
            polylines: Set<Polyline>.of(_polylines.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // ── Search bar ─────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.fieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.fieldStroke),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      SvgPicture.asset(
                        'assets/images/search_Icon.svg',
                        height: 18,
                        colorFilter: const ColorFilter.mode(AppColors.hintColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search for a parking spot...',
                            hintStyle: TextStyle(color: AppColors.hintColor, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: _searchController.clear,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.close, color: AppColors.hintColor, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Locating indicator ─────────────────────────────────
          if (_locationLoading)
            Positioned(
              top: 80, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.fieldColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fieldStroke),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                      ),
                      SizedBox(width: 8),
                      Text('Locating you…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Route info card ────────────────────────────────────
          if (_routeTarget != null)
            Positioned(
              bottom: 90, left: 20, right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fieldColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fieldStroke),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          children: [
                            const TextSpan(text: 'Routing to: '),
                            TextSpan(
                              text: _routeTarget!.name,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                            ),
                            if (_routeDistanceKm != null)
                              TextSpan(text: '  •  ${_routeDistanceKm!.toStringAsFixed(1)} km'),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearRoute,
                      child: const Icon(Icons.close, color: AppColors.hintColor, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          // ── FAB ───────────────────────────────────────────────
          Positioned(
            bottom: 24, right: 20,
            child: GestureDetector(
              onTap: _goToNearest,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 12)],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/curent_location_icon.svg',
                    height: 22,
                    colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
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

// ─────────────────────────────────────────────────────────────────
// Garage bottom sheet
// ─────────────────────────────────────────────────────────────────
class _GarageSheet extends StatelessWidget {
  final _Garage garage;
  final VoidCallback onGetDirections;
  const _GarageSheet({required this.garage, required this.onGetDirections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.fieldStroke, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  garage.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.hintColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('${garage.slots} spots available',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(icon: Icons.access_time_rounded, label: 'Open 24/7'),
              const SizedBox(width: 10),
              _Chip(icon: Icons.attach_money_rounded, label: 'EGP 10/hr'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onGetDirections,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Get Directions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fieldColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
