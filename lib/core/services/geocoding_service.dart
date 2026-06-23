import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationSearchResult {
  final double latitude;
  final double longitude;
  final String title;
  final String subtitle;

  const LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subtitle,
  });
}

class GeocodingService {
  GeocodingService._internal();
  static final GeocodingService instance = GeocodingService._internal();

  // Session-level reverse geocode cache keyed by '${lat},${lon}' rounded to
  // 4 decimal places (~11 m tolerance). Prevents repeat HTTP calls for the
  // same location in the same app session (PERF-018 fix).
  final Map<String, String> _reverseGeocodeCache = {};

  /// Safely reverse geocode coordinates without blocking the main thread.
  /// Results are cached in memory for the current app session (PERF-018 fix).
  /// First attempts a pure HTTP call to OpenStreetMap's Nominatim.
  /// If it fails, falls back to the native geocoding plugin.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_reverseGeocodeCache.containsKey(cacheKey)) {
      return _reverseGeocodeCache[cacheKey]!;
    }
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'RakniApp/1.0 (contact@rakniapp.com)',
      }).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final area = address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'] ??
              address['locality'] ??
              address['quarter'];
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state'] ??
              address['country'];

          final parts = [area, city]
              .whereType<String>()
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            final result = parts.join(', ');
            _reverseGeocodeCache[cacheKey] = result;
            return result;
          }
        }
        if (data['display_name'] != null) {
          final splitVal = data['display_name'].toString().split(',');
          final result = splitVal.take(2).join(', ').trim();
          _reverseGeocodeCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('GeocodingService: Nominatim failed: $e');
    }

    // Native fallback (try/catch to avoid crash, but avoid on debug emulator if possible)
    try {
      if (!kIsWeb && !kDebugMode) {
        final placemarks = await placemarkFromCoordinates(latitude, longitude)
            .timeout(const Duration(seconds: 3));
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final area = place.subLocality?.isNotEmpty == true
              ? place.subLocality
              : place.locality;
          final city = place.administrativeArea?.isNotEmpty == true
              ? place.administrativeArea
              : place.country;
          final parts = [area, city]
              .whereType<String>()
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          final result =
              parts.isEmpty ? 'Cairo, Egypt' : parts.join(', ');
          _reverseGeocodeCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('GeocodingService: Native fallback failed: $e');
    }

    _reverseGeocodeCache[cacheKey] = 'Cairo, Egypt';
    return 'Cairo, Egypt';
  }

  /// Safely search for locations by address/query.
  Future<List<LocationSearchResult>> searchLocation(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=eg&limit=5&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'RakniApp/1.0 (contact@rakniapp.com)',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>?;
          final title = address != null
              ? (address['road'] ?? address['amenity'] ?? address['building'] ?? address['suburb'] ?? query)
              : query;
          final restAddress = item['display_name'].toString().split(',').skip(1).join(', ').trim();
          return LocationSearchResult(
            latitude: double.parse(item['lat']),
            longitude: double.parse(item['lon']),
            title: title.toString(),
            subtitle: restAddress.isNotEmpty ? restAddress : 'Egypt',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('GeocodingService: Nominatim search failed: $e');
    }

    // Native fallback (avoid on debug emulator)
    try {
      if (!kIsWeb && !kDebugMode) {
        final locations = await locationFromAddress('$query, Cairo, Egypt')
            .timeout(const Duration(seconds: 4));
        final results = <LocationSearchResult>[];
        for (final loc in locations.take(5)) {
          final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude)
              .timeout(const Duration(seconds: 2));
          final place = placemarks.isNotEmpty ? placemarks.first : null;
          results.add(
            LocationSearchResult(
              latitude: loc.latitude,
              longitude: loc.longitude,
              title: place?.name ?? query,
              subtitle: place != null ? '${place.street}, ${place.locality}' : 'Cairo, Egypt',
            ),
          );
        }
        return results;
      }
    } catch (e) {
      debugPrint('GeocodingService: Native search fallback failed: $e');
    }

    return const [];
  }
}
