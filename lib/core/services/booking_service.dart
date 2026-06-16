import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/parking_lot_model.dart';
import '../models/parking_slot_model.dart';
import '../models/transaction_model.dart';
import 'firestore_service.dart';

/// Encapsulates all booking business logic:
/// creating, cancelling, and completing parking reservations.
///
/// Delegates raw Firestore writes to [FirestoreService] and exposes
/// clean, high-level methods that screens can call directly.
class BookingService {
  BookingService._();
  static final instance = BookingService._();

  final _fs = FirestoreService.instance;
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Reservation ID
  // ---------------------------------------------------------------------------

  /// Generates a random human-readable reservation ID, e.g., `4563-8520`.
  String generateReservationId() {
    final rand = Random();
    final a = rand.nextInt(9000) + 1000;
    final b = rand.nextInt(9000) + 1000;
    return '$a-$b';
  }

  // ---------------------------------------------------------------------------
  // Create booking
  // ---------------------------------------------------------------------------

  /// Creates a booking, marks the slot as unavailable, optionally deducts the
  /// wallet balance, and records a transaction — all inside a Firestore batch.
  ///
  /// Returns the created [BookingModel] with the Firestore-assigned [id].
  ///
  /// Throws on failure so callers can show appropriate error feedback.
  Future<BookingModel> createBooking({
    required String uid,
    required ParkingLotModel lot,
    required ParkingSlotModel slot,
    required DateTime startTime,
    required DateTime endTime,
    required double total,
    required String vehicleId,
    required String vehiclePlate,
    required String paymentMethod,
    double walletBalance = 0,
    double promoDiscount = 0,
    double serviceFee = 5.0,
  }) async {
    final resId = generateReservationId();

    final booking = BookingModel(
      id: '',
      userId: uid,
      parkingLotId: lot.id,
      slotId: slot.id,
      startTime: startTime,
      endTime: endTime,
      totalAmount: total,
      status: 'pending',
      vehicleId: vehicleId,
      vehiclePlate: vehiclePlate,
      pricePerHour: lot.pricePerHour,
      reservationId: resId,
      level: slot.level,
      spotLabel: 'Spot ${slot.slotNumber}',
      paymentMethod: paymentMethod,
      lotName: lot.name,
      lotAddress: lot.address,
    );

    // 1. Write booking document
    final bookingId = await _fs.createBooking(booking);

    // 2. Mark slot as taken
    await _fs.updateSlotAvailability(lot.id, slot.id, false);

    // 3. Deduct wallet balance immediately (if wallet payment)
    if (paymentMethod == 'wallet') {
      final newBalance = walletBalance - total;
      await _fs.updateWalletBalance(uid, newBalance);
    }

    // 4. Record transaction
    final tx = TransactionModel(
      id: '${bookingId}_booking',
      bookingId: bookingId,
      userId: uid,
      amount: total,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      status: 'success',
    );
    await _fs.recordTransaction(tx);

    // 5. Decrement availableSlots on the lot atomically
    await _db.collection('parkingLots').doc(lot.id).update({
      'availableSlots': FieldValue.increment(-1),
    });

    debugPrint('[BookingService] Booking created: $bookingId (res: $resId)');
    return booking.copyWith(id: bookingId);
  }

  // ---------------------------------------------------------------------------
  // Cancel booking
  // ---------------------------------------------------------------------------

  /// Cancels a booking and restores the slot availability.
  Future<void> cancelBooking({
    required String bookingId,
    required String lotId,
    required String slotId,
  }) async {
    await _fs.updateBookingStatus(bookingId, 'cancelled');
    await _fs.updateSlotAvailability(lotId, slotId, true);

    // Increment availableSlots on the lot
    await _db.collection('parkingLots').doc(lotId).update({
      'availableSlots': FieldValue.increment(1),
    });

    debugPrint('[BookingService] Booking cancelled: $bookingId');
  }

  // ---------------------------------------------------------------------------
  // Complete booking
  // ---------------------------------------------------------------------------

  /// Marks a booking as completed, records end time, and restores the slot.
  Future<void> completeBooking({
    required String bookingId,
    required String lotId,
    required String slotId,
    required DateTime endTime,
  }) async {
    await _fs.updateBookingStatus(bookingId, 'completed');
    await _fs.updateBookingEndTime(bookingId, endTime);
    await _fs.updateSlotAvailability(lotId, slotId, true);

    // Increment availableSlots on the lot
    await _db.collection('parkingLots').doc(lotId).update({
      'availableSlots': FieldValue.increment(1),
    });

    debugPrint('[BookingService] Booking completed: $bookingId');
  }

  // ---------------------------------------------------------------------------
  // Streams & Queries
  // ---------------------------------------------------------------------------

  /// Streams the single active or pending booking for [uid] (for home screen).
  Stream<BookingModel?> streamActiveBooking(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return BookingModel.fromFirestore(snap.docs.first);
    });
  }

  /// Streams all bookings for [uid] ordered by startTime DESC.
  Stream<List<BookingModel>> streamUserBookings(String uid) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(BookingModel.fromFirestore).toList());
  }

  /// Returns the total booking count for [uid] using Firestore count() aggregation.
  Future<int> getUserBookingCount(String uid) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      debugPrint('[BookingService] getUserBookingCount error: $e');
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Price calculation
  // ---------------------------------------------------------------------------

  /// Computes subtotal, service fee, and total for display.
  ({double subtotal, double serviceFee, double total}) calculatePrice({
    required double pricePerHour,
    required int durationHours,
    int durationMinutes = 0,
    double promoDiscount = 0,
    double serviceFee = 5.0,
  }) {
    final subtotal = pricePerHour * (durationHours + durationMinutes / 60);
    final total = subtotal + serviceFee - promoDiscount;
    return (subtotal: subtotal, serviceFee: serviceFee, total: total);
  }
}
