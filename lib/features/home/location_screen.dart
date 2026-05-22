import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _currentLoading = false;
  bool _searching = false;
  String _currentSubtitle = 'Tap to detect your location';
  String _query = '';
  List<_LocationResult> _results = const [];

  static const List<_LocationResult> _savedLocations = [
    _LocationResult(
      title: 'Home',
      subtitle: 'Villa 42, 5th Settlement, New Cairo',
      icon: Icons.home_rounded,
    ),
    _LocationResult(
      title: 'Office',
      subtitle: 'Cloud Tower, North 90th St, New Cairo',
      icon: Icons.work_rounded,
    ),
  ];

  static const List<_LocationResult> _recentLocations = [
    _LocationResult(
      title: 'Cairo Festival City Mall',
      subtitle: 'New Cairo, Cairo',
      icon: Icons.history_rounded,
    ),
    _LocationResult(
      title: 'Waterway 2',
      subtitle: '5th Settlement, New Cairo',
      icon: Icons.history_rounded,
    ),
    _LocationResult(
      title: 'Point 90 Mall',
      subtitle: 'AUC Avenue, New Cairo',
      icon: Icons.history_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _controller.text.trim();
    if (value == _query) return;

    setState(() => _query = value);
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() {
        _searching = false;
        _results = const [];
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchLocation(value),
    );
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _searching = true);

    try {
      final locations = await locationFromAddress('$query, Cairo, Egypt');
      final results = <_LocationResult>[];

      for (final location in locations.take(5)) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final placemark = placemarks.isNotEmpty ? placemarks.first : null;
        results.add(
          _LocationResult(
            title: _formatTitle(placemark, query),
            subtitle: _formatSubtitle(placemark),
            icon: Icons.location_on_rounded,
          ),
        );
      }

      if (!mounted || query != _controller.text.trim()) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = const []);
    } finally {
      if (mounted && query == _controller.text.trim()) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _currentLoading = true;
      _currentSubtitle = 'Detecting location...';
    });

    try {
      // Geolocator works on web through the browser Geolocation API. It needs
      // HTTPS in production, while localhost is allowed during development.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setCurrentStatus('Location services are disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setCurrentStatus('Location permission needed');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setCurrentStatus('Enable location in settings');
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

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final locationText = _formatSubtitle(place);
      if (!mounted) return;
      Navigator.pop(context, locationText);
    } catch (_) {
      _setCurrentStatus('Could not detect location');
    }
  }

  void _setCurrentStatus(String message) {
    if (!mounted) return;
    setState(() {
      _currentLoading = false;
      _currentSubtitle = message;
    });
  }

  String _formatTitle(Placemark? place, String fallback) {
    final candidates = [
      place?.name,
      place?.street,
      place?.subLocality,
      fallback,
    ];
    return candidates
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty)
        .trim();
  }

  String _formatSubtitle(Placemark? place) {
    if (place == null) return 'Cairo, Egypt';
    final parts =
        [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.country,
            ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
    return parts.isEmpty ? 'Cairo, Egypt' : parts.join(', ');
  }

  void _selectLocation(_LocationResult location) {
    Navigator.pop(context, location.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search,
                    color: AppColors.hintColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: _controller.clear,
                    )
                  else
                    const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _currentLoading ? null : _useCurrentLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _currentLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondary,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/images/curent_location_icon.svg',
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                AppColors.secondary,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Use current location',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentSubtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: AppColors.fieldStroke,
            indent: 20,
            endIndent: 20,
            thickness: 1,
          ),
          Expanded(
            child: isSearching ? _buildSearchResults() : _buildDefaultLists(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No locations found',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildLocationItem(_results[index]),
    );
  }

  Widget _buildDefaultLists() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 12),
        _buildSectionLabel('SAVED LOCATIONS'),
        ..._savedLocations.map(_buildLocationItem),
        const SizedBox(height: 12),
        const Divider(
          color: AppColors.fieldStroke,
          indent: 20,
          endIndent: 20,
          thickness: 1,
        ),
        const SizedBox(height: 12),
        _buildSectionLabel('RECENT SEARCHES'),
        ..._recentLocations.map(_buildLocationItem),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLocationItem(_LocationResult location) {
    return InkWell(
      onTap: () => _selectLocation(location),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                location.icon,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationResult {
  final String title;
  final String subtitle;
  final IconData icon;

  const _LocationResult({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
