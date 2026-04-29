import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/car_model.dart';
import '../models/vehicle_model.dart';
import '../models/parking_lot_model.dart';
import '../models/parking_slot_model.dart';
import '../models/booking_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/wallet_model.dart';
import '../utils/image_utils.dart';


/// Singleton service that provides a typed interface to Cloud Firestore.
///
/// Collections layout:
///   users/{uid}           — user profile data
///   cars/{uid}            — car data linked to the user
///   parkingLots/{lotId}   — parking lot details
///   bookings/{bookingId}  — reservation records
///   transactions/{txId}   — payment records
///   notifications/{id}    — user notifications
///   reviews/{id}         — parking lot reviews
///   wallets/{uid}        — user wallet balance
class FirestoreService {
  FirestoreService._internal();

  factory FirestoreService() => instance;

  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _cars =>
      _db.collection('cars');

  CollectionReference<Map<String, dynamic>> get _parkingLots =>
      _db.collection('parkingLots');

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _wallets =>
      _db.collection('wallets');

  // ---------------------------------------------------------------------------
  // User data
  // ---------------------------------------------------------------------------

  /// Saves user data to `users/{uid}`.
  ///
  /// Uses [SetOptions.merge] so existing fields are preserved.
  /// A `updatedAt` timestamp is injected automatically.
  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    try {
      final payload = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _users.doc(uid).set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Failed to save user data: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Unexpected error saving user data: $e');
    }
  }

  /// Retrieves the `users/{uid}` document as a [UserModel].
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    } catch (e) {
      throw Exception('Error fetching user model: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Car data
  // ---------------------------------------------------------------------------

  /// Saves car data to `cars/{uid}`.
  Future<void> saveCarData(String uid, Map<String, dynamic> data) async {
    try {
      final payload = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _cars.doc(uid).set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Failed to save car data: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Unexpected error saving car data: $e');
    }
  }

  /// Retrieves the `cars/{uid}` document as a [CarModel].
  Future<CarModel?> getCarModel(String uid) async {
    try {
      final snapshot = await _cars.doc(uid).get();
      if (!snapshot.exists) return null;
      return CarModel.fromFirestore(snapshot);
    } catch (e) {
      throw Exception('Error fetching car model: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Vehicle data (subcollection)
  // ---------------------------------------------------------------------------

  /// Adds a vehicle to `users/{uid}/vehicles`.
  Future<void> addVehicle(String uid, VehicleModel vehicle) async {
    try {
      final payload = {
        ...vehicle.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(uid).collection('vehicles').add(payload);
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  /// Adds a vehicle, optionally converting [imageFile] to a Base64 data URI.
  Future<void> addVehicleWithImage(
    String uid,
    VehicleModel vehicle, {
    XFile? imageFile,
  }) async {
    try {
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await ImageUtils.xFileToBase64(imageFile);
      }

      final payload = {
        ...vehicle.toFirestore(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(uid).collection('vehicles').add(payload);
    } catch (e) {
      throw Exception('Error adding vehicle with image: $e');
    }
  }

  /// Streams vehicles for a specific user.
  Stream<List<VehicleModel>> streamVehicles(String uid) {
    return _users.doc(uid).collection('vehicles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList();
    });
  }

  /// Deletes a vehicle from `users/{uid}/vehicles/{vehicleId}`.
  Future<void> deleteVehicle(String uid, String vehicleId) async {
    try {
      await _users.doc(uid).collection('vehicles').doc(vehicleId).delete();
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  /// Updates a vehicle in `users/{uid}/vehicles/{vehicleId}`.
  Future<void> updateVehicle(String uid, String vehicleId, VehicleModel vehicle) async {
    try {
      final payload = {
        ...vehicle.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(uid).collection('vehicles').doc(vehicleId).update(payload);
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  /// Updates a vehicle, optionally converting [imageFile] to a Base64 data URI.
  Future<void> updateVehicleWithImage(
    String uid,
    String vehicleId,
    VehicleModel vehicle, {
    XFile? imageFile,
  }) async {
    try {
      String? imageUrl = vehicle.imageUrl;

      if (imageFile != null) {
        imageUrl = await ImageUtils.xFileToBase64(imageFile);
      }

      final payload = {
        ...vehicle.toFirestore(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(uid).collection('vehicles').doc(vehicleId).update(payload);
    } catch (e) {
      throw Exception('Error updating vehicle with image: $e');
    }
  }

  /// Sets the specified vehicle as the default, clearing the flag on all others.
  Future<void> setDefaultVehicle(String uid, String vehicleId) async {
    try {
      final snapshot = await _users.doc(uid).collection('vehicles').get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == vehicleId});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error setting default vehicle: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Parking Lot & Slot data
  // ---------------------------------------------------------------------------

  /// Retrieves all parking lots.
  Future<List<ParkingLotModel>> getParkingLots() async {
    try {
      final snapshot = await _parkingLots.get();
      return snapshot.docs.map((doc) => ParkingLotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching parking lots: $e');
    }
  }

  /// Retrieves slots for a specific lot.
  Future<List<ParkingSlotModel>> getParkingSlots(String lotId) async {
    try {
      final snapshot = await _parkingLots.doc(lotId).collection('slots').get();
      return snapshot.docs.map((doc) => ParkingSlotModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching parking slots: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Bookings & Transactions
  // ---------------------------------------------------------------------------

  /// Creates a new booking.
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _bookings.add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  /// Retrieves bookings for a specific user.
  Future<List<BookingModel>> getUserBookings(String uid) async {
    try {
      final snapshot = await _bookings.where('userId', isEqualTo: uid).get();
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching user bookings: $e');
    }
  }

  /// Records a transaction.
  Future<void> recordTransaction(TransactionModel transaction) async {
    try {
      await _transactions.doc(transaction.id).set(transaction.toFirestore());
    } catch (e) {
      throw Exception('Error recording transaction: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Streams notifications for a specific user.
  Stream<List<NotificationModel>> streamNotifications(String uid) {
    return _notifications
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Marks a notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  /// Adds a review for a parking lot.
  Future<void> addReview(ReviewModel review) async {
    await _reviews.add(review.toFirestore());
  }

  /// Streams reviews for a specific parking lot.
  Stream<List<ReviewModel>> streamParkingLotReviews(String lotId) {
    return _reviews
        .where('parkingLotId', isEqualTo: lotId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------

  /// Gets the wallet for a specific user.
  Future<WalletModel?> getWallet(String uid) async {
    final doc = await _wallets.doc(uid).get();
    if (doc.exists) {
      return WalletModel.fromFirestore(doc);
    }
    return null;
  }

  /// Updates the user's wallet balance.
  Future<void> updateWalletBalance(String uid, double newBalance) async {
    await _wallets.doc(uid).set({
      'balance': newBalance,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

