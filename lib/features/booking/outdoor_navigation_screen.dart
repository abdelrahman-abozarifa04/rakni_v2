import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rakni_v2/core/models/booking_model.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
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
  StreamSubscription<Position>? _positionStreamSubscription;

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
    ThemeService.instance.addListener(_onThemeChanged);
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
    ThemeService.instance.removeListener(_onThemeChanged);
    _simulationTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
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

  void _updateRouteForUserLocation(LatLng userLoc, double? heading) {
    final dest = _destination;
    
    // 1. حساب المسافة المباشرة للوجهة النهائية
    final distanceToDest = _distKm(userLoc, dest);
    if (distanceToDest < 0.02) { // أقل من 20 متر = وصلنا
      _positionStreamSubscription?.cancel();
      setState(() {
        _hasArrived = true;
        _isNavigating = false;
        _userLocation = dest;
        _routePoints = [];
      });
      return;
    }

    // 2. تطبيق منطق الـ Map Matching / Snapping to Route
    LatLng snappedLocation = userLoc; // القيمة الافتراضية لو ملقيناش خط قريب
    int closestSegmentIndex = 0;
    double minDistanceToSegment = double.maxFinite;

    if (_routePoints.length > 1) {
      // نلف على كل القطع المستقيمة في المسار المتبقي
      for (int i = 0; i < _routePoints.length - 1; i++) {
        final p1 = _routePoints[i];
        final p2 = _routePoints[i + 1];
        
        // حساب النقطة المسقطة (Projected Point) على القطعة المستقيمة
        final projected = _findNearestPointOnSegment(userLoc, p1, p2);
        final dist = _distKm(userLoc, projected);
        
        if (dist < minDistanceToSegment) {
          minDistanceToSegment = dist;
          snappedLocation = projected;
          closestSegmentIndex = i;
        }
      }
    }

    // حد الأمان (Threshold): لو الإشارة الحقيقية بعيدة أكتر من 25 متر عن المسار، 
    // ده معناه إن المستخدم غالباً غير مساره (Off-Route)، ساعتها مش هنعمل Snap وهنسيب الإحداثيات خام
    if (minDistanceToSegment > 0.025) { 
      snappedLocation = userLoc;
      closestSegmentIndex = 0; // إعادة ضبط أو ترك المسار كما هو
    }

    setState(() {
      // السهم هيتحرك على النقطة المربوطة بالطريق بالظبط!
      _userLocation = snappedLocation; 
      
      // تقليم (Pruning) النقط اللي عديناها بناءً على القطعة المستقيمة الأقرب
      if (_routePoints.isNotEmpty && closestSegmentIndex < _routePoints.length) {
        _routePoints = [snappedLocation, ..._routePoints.sublist(closestSegmentIndex + 1)];
      }

      _distanceRemaining = _distKm(snappedLocation, dest);
      _durationRemainingMinutes = (_distanceRemaining * 2.0).round();
      if (_durationRemainingMinutes < 1) _durationRemainingMinutes = 1;

      // تحديث الإرشادات ديناميكياً
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

    // 3. تحريك الكاميرا بسلاسة نحو النقطة المربوطة بالطريق
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: snappedLocation,
          zoom: 17,
          bearing: heading ?? 45,
          tilt: 45,
        ),
      ),
    );
  }

  /// دالة رياضية لحساب أقرب نقطة على قطعة مستقيمة (بين p1 و p2) من نقطة خارجية (point)
  LatLng _findNearestPointOnSegment(LatLng point, LatLng p1, LatLng p2) {
    final double x = point.latitude;
    final double y = point.longitude;
    final double x1 = p1.latitude;
    final double y1 = p1.longitude;
    final double x2 = p2.latitude;
    final double y2 = p2.longitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) return p1;

    // حساب معامل الإسقاط (Projection factor)
    double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    // حصر النقطة داخل حدود القطعة المستقيمة (بين p1 و p2)
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    return LatLng(x1 + t * dx, y1 + t * dy);
  }


  Future<void> _startNavigation() async {
    // 1. Request location permission and get current position
    Position? pos;
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationServicesEnabled = prefs.getBool('setting_location_services') ?? true;
      if (locationServicesEnabled) {
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

    // 3. Animate camera to focus on the user initial location
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: 17,
            bearing: pos?.heading ?? 45,
            tilt: 45,
          ),
        ),
      );
    }

    // 4. Cancel any running subscriptions/simulations
    _positionStreamSubscription?.cancel();
    _simulationTimer?.cancel();

    // 5. Start real GPS tracking using getPositionStream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // trigger updates on 1 meter movements
    );
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);
      _updateRouteForUserLocation(currentLatLng, position.heading);
    }, onError: (err) {
      debugPrint('Geolocator stream error: $err');
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
            style: ThemeService.instance.isDark ? _darkMapStyle : _lightMapStyle,
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
                child: Icon(Icons.my_location,
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
              Icon(Icons.directions_car_rounded, color: AppColors.secondary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Navigate to ${widget.parkingLot.name}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Start live GPS-style navigation to the garage, or skip if you are already at the entrance.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 20),
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
                  child: Text(
                    'Start Navigation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 12),
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
                    side: BorderSide(color: AppColors.fieldStroke),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
            child: Icon(Icons.turn_right, color: Colors.black, size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _instructions[_currentInstruction],
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
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
              child: Icon(Icons.close,
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
              child: Icon(Icons.close,
                  color: AppColors.white, size: 20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_durationRemainingMinutes min',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
                Text(
                  '${_distanceRemaining.toStringAsFixed(1)} km  •  ${TimeOfDay.now().format(context)}',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
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
              child: Icon(Icons.alt_route,
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
          border: Border(
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
                child: Icon(Icons.location_on,
                    color: AppColors.secondary, size: 36),
              ),
            ),
            SizedBox(height: 16),
            Text("You've Arrived!",
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              widget.parkingLot.name,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 24),
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

  static const String _lightMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#F6F7F4"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#4A5568"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#EAECEE"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#D8EDCD"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#D8EDCD"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#718096"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#BEDFB3"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#D1D5DB"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#4A5568"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#F7FAFC"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#2D3748"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#718096"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#BEE3F8"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#2B6CB0"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#718096"}]}
]
''';
}

