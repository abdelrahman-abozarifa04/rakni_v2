import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
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

  CollectionReference<Map<String, dynamic>> get _cars => _db.collection('cars');

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
      final payload = {...data, 'updatedAt': FieldValue.serverTimestamp()};
      await _users.doc(uid).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: error saving user data: $e');
    }
  }

  /// Retrieves the `users/{uid}` document as a [UserModel].
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    } catch (e) {
      debugPrint('FirestoreService: error getting user model: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Car data
  // ---------------------------------------------------------------------------

  /// Saves car data to `cars/{uid}`.
  Future<void> saveCarData(String uid, Map<String, dynamic> data) async {
    try {
      final payload = {...data, 'updatedAt': FieldValue.serverTimestamp()};
      await _cars.doc(uid).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: error saving car data: $e');
    }
  }

  /// Retrieves the `cars/{uid}` document as a [CarModel].
  Future<CarModel?> getCarModel(String uid) async {
    try {
      final snapshot = await _cars.doc(uid).get();
      if (!snapshot.exists) return null;
      return CarModel.fromFirestore(snapshot);
    } catch (e) {
      debugPrint('FirestoreService: error getting car model: $e');
      return null;
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
      debugPrint('FirestoreService: error adding vehicle: $e');
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
      debugPrint('FirestoreService: error adding vehicle with image: $e');
    }
  }

  /// Streams vehicles for a specific user.
  ///
  /// Returns the direct Firestore snapshot stream \u2014 no StreamController wrapper
  /// (PERF-013 fix). Emits a REAL empty list when the user has no vehicles;
  /// never fabricates placeholder cars. An empty list is the signal the UI uses
  /// to block booking and prompt the user to add a real vehicle.
  Stream<List<VehicleModel>> streamVehicles(String uid) {
    return _users
        .doc(uid)
        .collection('vehicles')
        .snapshots()
        .map((snap) => snap.docs.map(VehicleModel.fromFirestore).toList());
  }

  /// Deletes a vehicle from `users/{uid}/vehicles/{vehicleId}`.
  Future<void> deleteVehicle(String uid, String vehicleId) async {
    try {
      await _users.doc(uid).collection('vehicles').doc(vehicleId).delete();
    } catch (e) {
      debugPrint('FirestoreService: error deleting vehicle: $e');
    }
  }

  /// Returns `true` if a vehicle with [plateNumber] already exists for [uid].
  ///
  /// Queries `users/{uid}/vehicles` where `plateNumber == plateNumber`, limit 1.
  Future<bool> isPlateNumberTaken(String uid, String plateNumber) async {
    try {
      final snapshot = await _users
          .doc(uid)
          .collection('vehicles')
          .where('plateNumber', isEqualTo: plateNumber)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FirestoreService: error checking plate number: $e');
      return false; // Allow on error to avoid blocking users
    }
  }

  /// Updates a vehicle in `users/{uid}/vehicles/{vehicleId}`.
  Future<void> updateVehicle(
    String uid,
    String vehicleId,
    VehicleModel vehicle,
  ) async {
    try {
      final payload = {
        ...vehicle.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _users
          .doc(uid)
          .collection('vehicles')
          .doc(vehicleId)
          .update(payload);
    } catch (e) {
      debugPrint('FirestoreService: error updating vehicle: $e');
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
      await _users
          .doc(uid)
          .collection('vehicles')
          .doc(vehicleId)
          .update(payload);
    } catch (e) {
      debugPrint('FirestoreService: error updating vehicle with image: $e');
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
      debugPrint('FirestoreService: error setting default vehicle: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Parking Lot & Slot data
  // ---------------------------------------------------------------------------

  /// Retrieves all parking lots.
  /// Returns an empty list if Firestore has no documents.
  /// Throws on network/permission errors so the UI can show an error state.
  /// NEVER returns mock data in production (PERF-004 fix).
  Future<List<ParkingLotModel>> getParkingLots() async {
    final snapshot = await _parkingLots.get();
    return snapshot.docs
        .map((doc) => ParkingLotModel.fromFirestore(doc))
        .toList();
  }


  /// Retrieves a single parking lot by ID.
  /// Returns null when the document does not exist or on network error.
  /// NEVER falls back to mock data (PERF-005 fix).
  Future<ParkingLotModel?> getParkingLot(String lotId) async {
    try {
      final doc = await _parkingLots.doc(lotId).get();
      if (!doc.exists) return null;
      return ParkingLotModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreService] getParkingLot error: $e');
      return null;
    }
  }

  /// Retrieves slots for a specific lot.
  /// Returns an empty list when the lot has no slots configured.
  /// NEVER returns mock data (PERF-006 fix).
  Future<List<ParkingSlotModel>> getParkingSlots(String lotId) async {
    try {
      final snapshot =
          await _parkingLots.doc(lotId).collection('slots').get();
      return snapshot.docs
          .map((doc) => ParkingSlotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getParkingSlots error: $e');
      rethrow;
    }
  }

  /// Streams parking slots for a specific lot in real-time.
  /// Returns the direct Firestore stream — no StreamController wrapper,
  /// no mock data fallback (PERF-006 + PERF-007 fix).
  Stream<List<ParkingSlotModel>> streamParkingSlots(String lotId) {
    return _parkingLots
        .doc(lotId)
        .collection('slots')
        .snapshots()
        .map((snap) =>
            snap.docs.map(ParkingSlotModel.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // Bookings & Transactions
  // ---------------------------------------------------------------------------

  /// Creates a new booking.
  /// Creates a new booking.
  /// Throws on Firestore write failure — callers must catch and show error state.
  /// NEVER returns a fake booking ID on error (production safety rule).
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _bookings.add(booking.toFirestore());
    return docRef.id;
  }

  /// Retrieves bookings for a specific user (one-time fetch).
  Future<List<BookingModel>> getUserBookings(String uid) async {
    try {
      final snapshot = await _bookings
          .where('userId', isEqualTo: uid)
          .orderBy('startTime', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] Error in getUserBookings: $e');
      return [];
    }
  }

  /// Streams the most recent 50 bookings for a specific user in real-time.
  ///
  /// Uses orderBy + limit to cap Firestore reads (PERF-014 fix).
  /// Returns the direct Firestore stream — no StreamController wrapper.
  ///
  /// NOTE: requires a composite Firestore index on (userId ASC, startTime DESC).
  /// The first run on a fresh project will log a console URL to create it.
  Stream<List<BookingModel>> streamUserBookings(String uid) {
    return _bookings
        .where('userId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(BookingModel.fromFirestore).toList());
  }



  /// Streams the active booking for a user (status == 'active'), limit 1.
  Stream<BookingModel?> streamActiveBooking(String uid) {
    late final StreamController<BookingModel?> controller;
    StreamSubscription? subscription;

    controller = StreamController<BookingModel?>(
      onListen: () {
        try {
          subscription = _bookings
              .where('userId', isEqualTo: uid)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                if (snapshot.docs.isEmpty) {
                  controller.add(null);
                } else {
                  controller.add(BookingModel.fromFirestore(snapshot.docs.first));
                }
              } catch (e) {
                debugPrint('[FirestoreService] Error mapping streamActiveBooking: $e');
                controller.add(null);
              }
            },
            onError: (error) {
              debugPrint('[FirestoreService] streamActiveBooking onError: $error');
              controller.add(null);
            },
          );
        } catch (e) {
          debugPrint('[FirestoreService] streamActiveBooking onListen catch: $e');
          controller.add(null);
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Gets the active booking for a user (one-time fetch).
  Future<BookingModel?> getActiveBooking(String uid) async {
    try {
      final snapshot = await _bookings
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return BookingModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('[FirestoreService] Error in getActiveBooking: $e');
      return null;
    }
  }

  /// Updates the status of a booking.
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookings.doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService: error updating booking status: $e');
    }
  }

  /// Updates the end time of a booking (for session extension or completion).
  Future<void> updateBookingEndTime(
      String bookingId, DateTime endTime) async {
    try {
      await _bookings.doc(bookingId).update({
        'endTime': Timestamp.fromDate(endTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService: error updating booking end time: $e');
    }
  }

  /// Updates the total amount of a booking.
  Future<void> updateBookingAmount(
      String bookingId, double totalAmount) async {
    try {
      await _bookings.doc(bookingId).update({
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService: error updating booking amount: $e');
    }
  }

  /// Marks a slot as available or unavailable.
  Future<void> updateSlotAvailability(
      String lotId, String slotId, bool isAvailable) async {
    try {
      await _parkingLots
          .doc(lotId)
          .collection('slots')
          .doc(slotId)
          .update({'isAvailable': isAvailable});
    } catch (e) {
      debugPrint('FirestoreService: error updating slot availability: $e');
    }
  }

  /// Records a transaction.
  Future<void> recordTransaction(TransactionModel transaction) async {
    try {
      await _transactions.doc(transaction.id).set(transaction.toFirestore());
    } catch (e) {
      debugPrint('FirestoreService: error recording transaction: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Streams notifications for a specific user.
  Stream<List<NotificationModel>> streamNotifications(String uid) {
    late final StreamController<List<NotificationModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<NotificationModel>>(
      onListen: () {
        try {
          subscription = _notifications
              .where('userId', isEqualTo: uid)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
                    .toList();
                list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                controller.add(list);
              } catch (e) {
                debugPrint('[FirestoreService] Error mapping streamNotifications: $e');
                controller.add([]);
              }
            },
            onError: (error) {
              debugPrint('[FirestoreService] streamNotifications onError: $error');
              controller.add([]);
            },
          );
        } catch (e) {
          debugPrint('[FirestoreService] streamNotifications onListen catch: $e');
          controller.add([]);
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Marks a notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('FirestoreService: error marking notification as read: $e');
    }
  }

  /// Adds a notification to Firestore and triggers a native system notification.
  Future<void> addNotification(
    String uid, {
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _notifications.add({
        'userId': uid,
        'title': title,
        'body': body,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': type,
      });


    } catch (e) {
      debugPrint('[FirestoreService] Error adding notification: $e');
    }
  }

  /// Sends a notification if the corresponding setting is enabled in SharedPreferences.
  Future<void> sendAppNotification(
    String uid, {
    required String title,
    required String body,
    required String type,
    String? settingKey,
  }) async {
    if (settingKey != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool(settingKey) ?? true;
        if (!enabled) return;
      } catch (e) {
        debugPrint('[FirestoreService] Error reading SharedPreferences: $e');
      }
    }
    await addNotification(uid, title: title, body: body, type: type);
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  /// Adds a review for a parking lot.
  Future<void> addReview(ReviewModel review) async {
    try {
      await _reviews.add(review.toFirestore());
    } catch (e) {
      debugPrint('FirestoreService: error adding review: $e');
    }
  }

  /// Streams reviews for a specific parking lot.
  Stream<List<ReviewModel>> streamParkingLotReviews(String lotId) {
    late final StreamController<List<ReviewModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<ReviewModel>>(
      onListen: () {
        try {
          subscription = _reviews
              .where('parkingLotId', isEqualTo: lotId)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => ReviewModel.fromFirestore(doc))
                    .toList();
                list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                controller.add(list);
              } catch (e) {
                debugPrint('[FirestoreService] Error mapping streamParkingLotReviews: $e');
                controller.add([]);
              }
            },
            onError: (error) {
              debugPrint('[FirestoreService] streamParkingLotReviews onError: $error');
              controller.add([]);
            },
          );
        } catch (e) {
          debugPrint('[FirestoreService] streamParkingLotReviews onListen catch: $e');
          controller.add([]);
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------

  /// Gets the wallet for a specific user.
  Future<WalletModel?> getWallet(String uid) async {
    try {
      final doc = await _wallets.doc(uid).get();
      if (doc.exists) {
        return WalletModel.fromFirestore(doc);
      }
      return WalletModel(userId: uid, balance: 350.0, lastUpdated: DateTime.now());
    } catch (_) {
      return WalletModel(userId: uid, balance: 350.0, lastUpdated: DateTime.now());
    }
  }

  /// Updates the user's wallet balance.
  Future<void> updateWalletBalance(String uid, double newBalance) async {
    try {
      await _wallets.doc(uid).set({
        'balance': newBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: error updating wallet balance: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  /// Streams transactions for a specific user ordered by timestamp DESC.
  Stream<List<TransactionModel>> streamUserTransactions(String uid) {
    late final StreamController<List<TransactionModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<TransactionModel>>(
      onListen: () {
        try {
          subscription = _transactions
              .where('userId', isEqualTo: uid)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => TransactionModel.fromFirestore(doc))
                    .toList();
                list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                controller.add(list);
              } catch (e) {
                debugPrint('[FirestoreService] Error mapping streamUserTransactions: $e');
                controller.add([]);
              }
            },
            onError: (error) {
              debugPrint('[FirestoreService] streamUserTransactions onError: $error');
              controller.add([]);
            },
          );
        } catch (e) {
          debugPrint('[FirestoreService] streamUserTransactions onListen catch: $e');
          controller.add([]);
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
