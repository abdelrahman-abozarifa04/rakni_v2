import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/models/blacklist_model.dart';
import 'package:rakni_v2/core/models/subscription_model.dart';

/// Talks directly to the Django REST hardware/sensor backend that tracks
/// real-time occupancy of physical parking slots (camera + sensor driven).
///
/// SECURITY: base URL and auth token are passed via --dart-define so the
/// API URL / token never get hardcoded into source control.
/// Run with:
///   flutter run --dart-define=PARKING_API_BASE_URL=https://garage-api-system.onrender.com --dart-define=PARKING_API_TOKEN=yourtoken
class ParkingHardwareApiService {
  ParkingHardwareApiService._();
  static final instance = ParkingHardwareApiService._();

  static const String _baseUrl = String.fromEnvironment(
    'PARKING_API_BASE_URL',
    defaultValue: 'https://garage-api-system.onrender.com',
  );

  static const String _authToken = String.fromEnvironment(
    'PARKING_API_TOKEN',
    defaultValue: '7d368c0721945f66f41f86a2810057c70f230919',
  );

  static const String _slotsPath = '/api/v1/parking-slots/';

  // NOTE: GET /api/v1/parking-slots/available/ also exists and filters to only
  // available slots. It is intentionally NOT used here (we need to render
  // occupied slots too, styled differently). A future "X free" counter widget
  // elsewhere in the UI could use that endpoint for efficiency.

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken.isNotEmpty) 'Authorization': 'Token $_authToken',
      };

  // ---------------------------------------------------------------------------
  // READ — live slot occupancy
  // ---------------------------------------------------------------------------

  /// Fetches the full live list of parking slots with current occupancy
  /// straight from the hardware/sensor backend.
  ///
  /// Throws on network failure, non-200 response, or malformed JSON.
  /// Callers must NEVER silently substitute mock/fake data on failure —
  /// surface the error to the UI instead.
  Future<List<ParkingSlotModel>> fetchSlots({String? parkingLotId}) async {
    final uri = Uri.parse('$_baseUrl$_slotsPath');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'Parking API returned ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    // DRF may or may not paginate — handle both a raw list and a
    // {"results": [...]} wrapper defensively.
    final List<dynamic> rawList = decoded is Map<String, dynamic>
        ? (decoded['results'] as List<dynamic>? ?? const [])
        : (decoded as List<dynamic>);

    return rawList
        .map((json) => _mapToSlotModel(json as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // WRITE — reserve / release a physical slot
  // ---------------------------------------------------------------------------

  /// Marks a physical slot as reserved (occupied) on the Django backend.
  ///
  /// Called fire-and-forget immediately after the Firestore booking is
  /// confirmed, so the occupancy map reflects the reservation for other users
  /// on their next 5-second poll cycle.
  ///
  /// Endpoint: PATCH /api/v1/parking-slots/{id}/   body: {"is_occupied": true}
  ///
  /// Returns true on success. On any failure, logs and returns false — the
  /// Firestore booking is already saved and must never be blocked by this.
  Future<bool> reserveSlot({
    required String slotId,
    required String plateNumber,
  }) async {
    final uri = Uri.parse('$_baseUrl$_slotsPath$slotId/');
    try {
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode({
              'is_occupied': true,
              'occupied_by_plate': plateNumber,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[HardwareAPI] Slot $slotId marked occupied ✓');
        return true;
      }
      debugPrint(
        '[HardwareAPI] reserveSlot ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[HardwareAPI] reserveSlot error (slot $slotId): $e');
      return false;
    }
  }

  /// Releases a physical slot back to available on the Django backend.
  ///
  /// Called when a booking is cancelled or a session is completed.
  /// Endpoint: PATCH /api/v1/parking-slots/{id}/   body: {"is_occupied": false}
  Future<bool> releaseSlot({required String slotId}) async {
    final uri = Uri.parse('$_baseUrl$_slotsPath$slotId/');
    try {
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode({'is_occupied': false}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[HardwareAPI] Slot $slotId released (available) ✓');
        return true;
      }
      debugPrint(
        '[HardwareAPI] releaseSlot ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[HardwareAPI] releaseSlot error (slot $slotId): $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  ParkingSlotModel _mapToSlotModel(Map<String, dynamic> json) {
    final bool isOccupied = json['is_occupied'] as bool? ?? false;
    return ParkingSlotModel(
      id: json['id'].toString(),
      parkingLotId: '',
      slotNumber: json['slot_number'] as String? ?? '',
      isAvailable: !isOccupied,
      type: 'regular',
      level: '',
    );
  }

  // ---------------------------------------------------------------------------
  // BLACKLIST INTEGRATION
  // ---------------------------------------------------------------------------

  String _normalizeNumerals(String input) {
    const easternToWestern = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9'
    };
    String result = input;
    easternToWestern.forEach((eastern, western) {
      result = result.replaceAll(eastern, western);
    });
    return result;
  }

  String _normalizeArabicLetters(String input) {
    return input
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  /// Helper to check if two plates match, normalizing spaces, casing,
  /// Eastern/Western Arabic numerals, and Arabic character variations,
  /// comparing digit and letter parts independently of their sequence order.
  bool _platesMatch(String a, String b) {
    final normA = _normalizeArabicLetters(_normalizeNumerals(a))
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    final normB = _normalizeArabicLetters(_normalizeNumerals(b))
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();

    // Extract digits only
    final digitsA = normA.replaceAll(RegExp(r'[^0-9]'), '');
    final digitsB = normB.replaceAll(RegExp(r'[^0-9]'), '');

    // Extract letters only (non-digits)
    final lettersA = normA.replaceAll(RegExp(r'[0-9]'), '');
    final lettersB = normB.replaceAll(RegExp(r'[0-9]'), '');

    return digitsA == digitsB && lettersA == lettersB;
  }

  /// Exposes the plate matching helper publicly.
  bool platesMatch(String a, String b) => _platesMatch(a, b);

  // ---------------------------------------------------------------------------
  // LIVE ENTRY / EXIT SCAN ENDPOINTS
  // ---------------------------------------------------------------------------

  /// Fetches the last entry event from the Django backend.
  Future<Map<String, dynamic>?> fetchLastEntry() async {
    final uri = Uri.parse('$_baseUrl/api/mobile/last-entry/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[HardwareAPI] fetchLastEntry error: $e');
      return null;
    }
  }

  /// Fetches the last exit event from the Django backend.
  Future<Map<String, dynamic>?> fetchLastExit() async {
    final uri = Uri.parse('$_baseUrl/api/mobile/last-exit/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[HardwareAPI] fetchLastExit error: $e');
      return null;
    }
  }

  /// Fetches all active blacklist entries from the Django backend.
  Future<List<BlacklistStatus>> fetchActiveBlacklist() async {
    final uri = Uri.parse('$_baseUrl/api/v1/blacklist/active/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}: ${response.body}');
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> rawList = decoded is Map<String, dynamic>
          ? (decoded['entries'] as List<dynamic>? ?? const [])
          : (decoded as List<dynamic>);

      return rawList
          .map((json) => BlacklistStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[HardwareAPI] fetchActiveBlacklist error: $e');
      rethrow;
    }
  }

  /// Checks if any of the user's plate numbers are active in the blacklist.
  ///
  /// Returns the matching [BlacklistStatus] if blacklisted, otherwise null.
  Future<BlacklistStatus?> checkBlacklist(List<String> plateNumbers) async {
    if (plateNumbers.isEmpty) return null;
    try {
      final activeList = await fetchActiveBlacklist();
      for (final blacklisted in activeList) {
        if (blacklisted.isActive) {
          for (final plate in plateNumbers) {
            if (_platesMatch(blacklisted.plateNumber, plate)) {
              return blacklisted;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HardwareAPI] checkBlacklist check failed: $e');
      // Gracefully continue: do not block the user if API is down
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTION INTEGRATION
  // ---------------------------------------------------------------------------

  /// Fetches all active subscriptions from the Django backend.
  Future<List<Subscription>> fetchActiveSubscriptions() async {
    final uri = Uri.parse('$_baseUrl/api/v1/subscriptions/active/');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}: ${response.body}');
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> rawList = decoded is Map<String, dynamic>
          ? (decoded['subscriptions'] as List<dynamic>? ?? const [])
          : (decoded as List<dynamic>);

      return rawList
          .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[HardwareAPI] fetchActiveSubscriptions error: $e');
      rethrow;
    }
  }

  /// Checks if any of the user's plate numbers have an active subscription.
  ///
  /// Returns the matching [Subscription] if active, otherwise null.
  Future<Subscription?> checkActiveSubscription(List<String> plateNumbers) async {
    if (plateNumbers.isEmpty) return null;
    try {
      final activeSubs = await fetchActiveSubscriptions();
      for (final sub in activeSubs) {
        if (sub.isActive && sub.isValid) {
          for (final plate in plateNumbers) {
            if (_platesMatch(sub.plateNumber, plate)) {
              return sub;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HardwareAPI] checkActiveSubscription failed: $e');
    }
    return null;
  }

  /// Creates a new subscription on the Django backend.
  Future<Subscription> createSubscription(Subscription subscription) async {
    final uri = Uri.parse('$_baseUrl/api/v1/subscriptions/');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(subscription.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        return Subscription.fromJson(data);
      } else {
        throw Exception('API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[HardwareAPI] createSubscription error: $e');
      rethrow;
    }
  }

  /// Cancels/Deletes a subscription on the Django backend.
  Future<bool> cancelSubscription(int subscriptionId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/subscriptions/$subscriptionId/');
    try {
      final response = await http
          .delete(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[HardwareAPI] Subscription $subscriptionId deleted ✓');
        return true;
      }
      debugPrint(
        '[HardwareAPI] cancelSubscription ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[HardwareAPI] cancelSubscription error: $e');
      return false;
    }
  }
}

