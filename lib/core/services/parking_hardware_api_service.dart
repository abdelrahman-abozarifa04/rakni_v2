import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rakni_v2/core/models/parking_slot_model.dart';

/// Talks directly to the Django REST hardware/sensor backend that tracks
/// real-time occupancy of physical parking slots (camera + sensor driven).
///
/// SECURITY: base URL and auth token are passed via --dart-define so the
/// ngrok tunnel URL / token never get hardcoded into source control.
/// Run with:
///   flutter run --dart-define=PARKING_API_BASE_URL=https://... --dart-define=PARKING_API_TOKEN=yourtoken
class ParkingHardwareApiService {
  ParkingHardwareApiService._();
  static final instance = ParkingHardwareApiService._();

  static const String _baseUrl = String.fromEnvironment(
    'PARKING_API_BASE_URL',
    defaultValue: 'https://overfill-barley-confront.ngrok-free.dev',
  );

  static const String _authToken = String.fromEnvironment(
    'PARKING_API_TOKEN',
    defaultValue: '',
  );

  static const String _slotsPath = '/api/v1/parking-slots/';

  // NOTE: GET /api/v1/parking-slots/available/ also exists and filters to only
  // available slots. It is intentionally NOT used here (we need to render
  // occupied slots too, styled differently). A future "X free" counter widget
  // elsewhere in the UI could use that endpoint for efficiency.

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // Required: ngrok's free-tier interceptor otherwise returns an
        // HTML warning page for every request (not just browser ones)
        // instead of JSON, breaking jsonDecode below.
        'ngrok-skip-browser-warning': 'true',
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
  Future<bool> reserveSlot({required String slotId}) async {
    final uri = Uri.parse('$_baseUrl$_slotsPath$slotId/');
    try {
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode({'is_occupied': true}),
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
}
