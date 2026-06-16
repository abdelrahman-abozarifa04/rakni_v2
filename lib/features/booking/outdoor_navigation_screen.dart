import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'gate_entry_scan_screen.dart';

class OutdoorNavigationScreen extends StatefulWidget {
  final BookingModel booking;
  final ParkingLotModel parkingLot;
  final ParkingSlotModel slot;
  final VehicleModel vehicle;

  const OutdoorNavigationScreen({
    super.key,
    required this.booking,
    required this.parkingLot,
    required this.slot,
    required this.vehicle,
  });

  @override
  State<OutdoorNavigationScreen> createState() =>
      _OutdoorNavigationScreenState();
}

class _OutdoorNavigationScreenState extends State<OutdoorNavigationScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _hasArrived = false;
  bool _isNavigating = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  double _distanceRemaining = 0.0;
  int _durationRemainingMinutes = 0;
  Timer? _simulationTimer;

  final List<String> _instructions = [
    'Turn right onto Main St.',
    'Continue straight for 500m',
    'Turn left onto Parking Ave.',
    'Your destination is on the right',
  ];
  int _currentInstruction = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Initialize preview location & straight polyline route
    final dest = _destination;
    _userLocation = LatLng(dest.latitude - 0.015, dest.longitude - 0.012);
    _routePoints = [_userLocation!, dest];
    _distanceRemaining = _distKm(_userLocation!, dest);
    _durationRemainingMinutes = (_distanceRemaining * 2.0).round();
    if (_durationRemainingMinutes < 1) _durationRemainingMinutes = 1;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _destination => LatLng(
        widget.parkingLot.latitude,
        widget.parkingLot.longitude,
      );

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.parkingLot.name),
        ),
        if (_userLocation != null)
          Marker(
            markerId: const MarkerId('current'),
            position: _userLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
      };

  Set<Polyline> get _polylines => {
        if (_routePoints.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            color: AppColors.secondary,
            width: 5,
            points: _routePoints,
          ),
      };

  double _distKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _rad(double d) => d * math.pi / 180;

  Future<void> _startNavigation() async {
    // 1. Request location permission and get current position
    Position? pos;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Geolocator error: $e');
    }

    final dest = _destination;
    LatLng startLoc = LatLng(dest.latitude - 0.015, dest.longitude - 0.012);
    if (pos != null) {
      startLoc = LatLng(pos.latitude, pos.longitude);
    }

    setState(() {
      _userLocation = startLoc;
      _isNavigating = true;
      _hasArrived = false;
      _distanceRemaining = _distKm(startLoc, dest);
      _durationRemainingMinutes = (_distanceRemaining * 2.0).round();
      if (_durationRemainingMinutes < 1) _durationRemainingMinutes = 1;
      _currentInstruction = 0;
      _routePoints = [startLoc, dest];
    });

    // 2. Fetch path using Directions API or simulation fallback
    try {
      final pp = PolylinePoints();
      final result = await pp.getRouteBetweenCoordinates(
        googleApiKey: const String.fromEnvironment('MAPS_API_KEY'),
        request: PolylineRequest(
          origin: PointLatLng(startLoc.latitude, startLoc.longitude),
          destination: PointLatLng(dest.latitude, dest.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        if (mounted) {
          setState(() {
            _routePoints = result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList();
          });
        }
      } else {
        _generateSimulatedRoute(startLoc, dest);
      }
    } catch (e) {
      debugPrint('Directions API error: $e');
      _generateSimulatedRoute(startLoc, dest);
    }

    // 3. Animate camera to focus on the user
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: 17,
            bearing: 45,
            tilt: 45,
          ),
        ),
      );
    }

    // 4. Start periodic simulation updates
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_routePoints.length <= 1) {
        timer.cancel();
        setState(() {
          _hasArrived = true;
          _isNavigating = false;
          _userLocation = dest;
        });
        return;
      }

      // Move marker to the next point
      final nextLoc = _routePoints[1];

      setState(() {
        _userLocation = nextLoc;
        _routePoints = _routePoints.sublist(1);
        _distanceRemaining = _distKm(nextLoc, dest);
        _durationRemainingMinutes = (_distanceRemaining * 2.0).round();
        if (_durationRemainingMinutes < 1) _durationRemainingMinutes = 1;

        // Dynamic instructions based on remaining path points
        final remaining = _routePoints.length;
        if (remaining > 10) {
          _currentInstruction = 0;
        } else if (remaining > 6) {
          _currentInstruction = 1;
        } else if (remaining > 3) {
          _currentInstruction = 2;
        } else {
          _currentInstruction = 3;
        }
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: nextLoc,
            zoom: 17,
            bearing: 45,
            tilt: 45,
          ),
        ),
      );
    });
  }

  void _generateSimulatedRoute(LatLng start, LatLng end) {
    final List<LatLng> pts = [];
    const steps = 15;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      // Add a realistic navigation curve using sine wave
      final curveOffset = math.sin(t * math.pi) * 0.002;
      pts.add(LatLng(lat + curveOffset, lng - curveOffset));
    }
    setState(() {
      _routePoints = pts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? _destination,
              zoom: 14,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: _darkMapStyle,
          ),
          // Top instruction bar
          if (_isNavigating && !_hasArrived)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildInstructionCard(),
                ),
              ),
            ),
          // Arrived overlay
          if (_hasArrived) _buildArrivedOverlay(),
          // Bottom prompt or stats bar
          if (!_hasArrived)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _isNavigating ? _buildBottomBar() : _buildPromptCard(),
            ),
          // Re-center button
          Positioned(
            right: 16,
            bottom: _hasArrived ? 280 : 140,
            child: GestureDetector(
              onTap: () {
                if (_userLocation != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(_userLocation!),
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldStroke),
                ),
                child: const Icon(Icons.my_location,
                    color: AppColors.secondary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded, color: AppColors.secondary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Navigate to ${widget.parkingLot.name}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start live GPS-style navigation to the garage, or skip if you are already at the entrance.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _startNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Navigation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _hasArrived = true;
                      _isNavigating = false;
                      _userLocation = _destination;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.fieldStroke),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip Navigation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.turn_right, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _instructions[_currentInstruction],
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Text(
                  'In 200m',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: const Icon(Icons.close,
                  color: AppColors.textSecondary, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: const Icon(Icons.close,
                  color: AppColors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_durationRemainingMinutes min',
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
                Text(
                  '${_distanceRemaining.toStringAsFixed(1)} km  •  ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentInstruction =
                    (_currentInstruction + 1) % _instructions.length;
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: const Icon(Icons.alt_route,
                  color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
              top: BorderSide(color: AppColors.fieldStroke)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.fieldStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  border:
                      Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const Icon(Icons.location_on,
                    color: AppColors.secondary, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text("You've Arrived!",
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              widget.parkingLot.name,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GateEntryScanScreen(
                    booking: widget.booking,
                    parkingLot: widget.parkingLot,
                    slot: widget.slot,
                    vehicle: widget.vehicle,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  SizedBox(width: 8),
                  Text('Start Parking',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#343434"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]}
]
''';
}

