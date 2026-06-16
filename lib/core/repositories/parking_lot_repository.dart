import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/parking_lot_model.dart';
import '../models/parking_slot_model.dart';

/// Singleton repository for all parking lot Firestore operations.
/// Follows the project pattern: never recreate, always extend through this class.
class ParkingLotRepository {
  ParkingLotRepository._();
  static final instance = ParkingLotRepository._();

  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Parking Lots
  // ---------------------------------------------------------------------------

  /// Real-time stream of ALL parking lots.
  Stream<List<ParkingLotModel>> streamParkingLots() {
    return _db.collection('parkingLots').snapshots().map(
      (snap) => snap.docs.map(ParkingLotModel.fromFirestore).toList(),
    );
  }

  /// Real-time stream of lots that have at least one available slot.
  Stream<List<ParkingLotModel>> streamAvailableLots() {
    return _db
        .collection('parkingLots')
        .where('availableSlots', isGreaterThan: 0)
        .snapshots()
        .map((snap) => snap.docs.map(ParkingLotModel.fromFirestore).toList());
  }

  /// Fetch a single lot by [lotId].
  Future<ParkingLotModel?> getLot(String lotId) async {
    try {
      final doc = await _db.collection('parkingLots').doc(lotId).get();
      if (!doc.exists) return null;
      return ParkingLotModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ParkingLotRepository] getLot error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Slots
  // ---------------------------------------------------------------------------

  /// Real-time stream of all slots for a given [lotId].
  Stream<List<ParkingSlotModel>> streamSlots(String lotId) {
    return _db
        .collection('parkingLots')
        .doc(lotId)
        .collection('slots')
        .snapshots()
        .map((snap) => snap.docs.map(ParkingSlotModel.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Client-side search by [query] against lot name and address.
  /// Firestore does not support full-text search natively, so we fetch all
  /// lots and filter locally (acceptable for small datasets).
  Future<List<ParkingLotModel>> searchLots(String query) async {
    try {
      final snap = await _db.collection('parkingLots').get();
      final all = snap.docs.map(ParkingLotModel.fromFirestore).toList();
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where(
            (lot) =>
                lot.name.toLowerCase().contains(q) ||
                lot.address.toLowerCase().contains(q),
          )
          .toList();
    } catch (e) {
      debugPrint('[ParkingLotRepository] searchLots error: $e');
      return [];
    }
  }
}
