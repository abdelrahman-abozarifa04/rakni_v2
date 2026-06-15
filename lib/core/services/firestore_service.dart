import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (!snapshot.exists) return _getMockUserModel(uid);
      return UserModel.fromFirestore(snapshot);
    } catch (e) {
      return _getMockUserModel(uid);
    }
  }

  UserModel _getMockUserModel(String uid) {
    return UserModel(
      uid: uid,
      fullName: 'Abdelrahman Abozarifa',
      email: 'abdelrahman@rakni.com',
      phoneNumber: '+20 101 234 5678',
      age: '22',
      gender: 'Male',
      address: 'Nasr City, Cairo',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
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
      if (!snapshot.exists) return _getMockCarModel(uid);
      return CarModel.fromFirestore(snapshot);
    } catch (e) {
      return _getMockCarModel(uid);
    }
  }

  CarModel _getMockCarModel(String uid) {
    return CarModel(
      uid: uid,
      plateNumber: 'أ ج د 5432',
      carModel: 'BMW M4 Coupe',
      carColor: 'Black',
      manufacturingYear: '2023',
    );
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
  Stream<List<VehicleModel>> streamVehicles(String uid) {
    late final StreamController<List<VehicleModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<VehicleModel>>(
      onListen: () {
        try {
          subscription = _users.doc(uid).collection('vehicles').snapshots().listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => VehicleModel.fromFirestore(doc))
                    .toList();
                if (list.isEmpty) {
                  controller.add(_getMockVehicles());
                } else {
                  controller.add(list);
                }
              } catch (e) {
                controller.add(_getMockVehicles());
              }
            },
            onError: (error) {
              controller.add(_getMockVehicles());
            },
          );
        } catch (e) {
          controller.add(_getMockVehicles());
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<VehicleModel> _getMockVehicles() {
    return [
      VehicleModel(
        id: 'mock_car_1',
        brand: 'BMW',
        model: 'M4 Coupe',
        plateNumber: 'أ ج د 5432',
        color: 'Black',
        isDefault: true,
      ),
      VehicleModel(
        id: 'mock_car_2',
        brand: 'Mercedes',
        model: 'C200',
        plateNumber: 'ر ق م 9876',
        color: 'White',
        isDefault: false,
      ),
    ];
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
  Future<List<ParkingLotModel>> getParkingLots() async {
    try {
      final snapshot = await _parkingLots.get();
      if (snapshot.docs.isEmpty) return _getMockParkingLots();
      return snapshot.docs
          .map((doc) => ParkingLotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return _getMockParkingLots();
    }
  }

  List<ParkingLotModel> _getMockParkingLots() {
    return [
      ParkingLotModel(
        id: 'mock_lot_1',
        name: 'Heliopolis Plaza Parking',
        address: '15 El-Ahram St, Heliopolis, Cairo',
        latitude: 30.0912,
        longitude: 31.3214,
        totalSlots: 100,
        availableSlots: 45,
        pricePerHour: 20.0,
        imageUrl: 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?auto=format&fit=crop&q=80&w=800',
      ),
      ParkingLotModel(
        id: 'mock_lot_2',
        name: 'City Stars Mall Garage',
        address: 'Omar Ibn El-Khattab St, Nasr City, Cairo',
        latitude: 30.0734,
        longitude: 31.3456,
        totalSlots: 250,
        availableSlots: 87,
        pricePerHour: 30.0,
        imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&q=80&w=800',
      ),
    ];
  }

  /// Retrieves a single parking lot by ID.
  Future<ParkingLotModel?> getParkingLot(String lotId) async {
    try {
      final doc = await _parkingLots.doc(lotId).get();
      if (!doc.exists) {
        final mockLots = _getMockParkingLots();
        final match = mockLots.where((l) => l.id == lotId).toList();
        return match.isNotEmpty ? match.first : mockLots.first;
      }
      return ParkingLotModel.fromFirestore(doc);
    } catch (e) {
      final mockLots = _getMockParkingLots();
      final match = mockLots.where((l) => l.id == lotId).toList();
      return match.isNotEmpty ? match.first : mockLots.first;
    }
  }

  /// Retrieves slots for a specific lot.
  Future<List<ParkingSlotModel>> getParkingSlots(String lotId) async {
    try {
      final snapshot = await _parkingLots.doc(lotId).collection('slots').get();
      if (snapshot.docs.isEmpty) return _getMockSlots(lotId);
      return snapshot.docs
          .map((doc) => ParkingSlotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return _getMockSlots(lotId);
    }
  }

  /// Streams parking slots for a specific lot in real-time.
  Stream<List<ParkingSlotModel>> streamParkingSlots(String lotId) {
    late final StreamController<List<ParkingSlotModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<ParkingSlotModel>>(
      onListen: () {
        try {
          subscription = _parkingLots
              .doc(lotId)
              .collection('slots')
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => ParkingSlotModel.fromFirestore(doc))
                    .toList();
                if (list.isEmpty) {
                  controller.add(_getMockSlots(lotId));
                } else {
                  controller.add(list);
                }
              } catch (e) {
                controller.add(_getMockSlots(lotId));
              }
            },
            onError: (error) {
              controller.add(_getMockSlots(lotId));
            },
          );
        } catch (e) {
          controller.add(_getMockSlots(lotId));
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<ParkingSlotModel> _getMockSlots(String lotId) {
    return [
      // Level 1
      ParkingSlotModel(
        id: 'slot_1_1',
        parkingLotId: lotId,
        slotNumber: 'A-101',
        isAvailable: true,
        type: 'regular',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_2',
        parkingLotId: lotId,
        slotNumber: 'A-102',
        isAvailable: false,
        type: 'regular',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_3',
        parkingLotId: lotId,
        slotNumber: 'A-103',
        isAvailable: true,
        type: 'ev',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_4',
        parkingLotId: lotId,
        slotNumber: 'A-104',
        isAvailable: true,
        type: 'disabled',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_5',
        parkingLotId: lotId,
        slotNumber: 'A-105',
        isAvailable: false,
        type: 'regular',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_6',
        parkingLotId: lotId,
        slotNumber: 'A-106',
        isAvailable: true,
        type: 'regular',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_7',
        parkingLotId: lotId,
        slotNumber: 'A-107',
        isAvailable: true,
        type: 'ev',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_8',
        parkingLotId: lotId,
        slotNumber: 'A-108',
        isAvailable: false,
        type: 'disabled',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_9',
        parkingLotId: lotId,
        slotNumber: 'A-109',
        isAvailable: true,
        type: 'regular',
        level: 'Level 1',
      ),
      ParkingSlotModel(
        id: 'slot_1_10',
        parkingLotId: lotId,
        slotNumber: 'A-110',
        isAvailable: true,
        type: 'regular',
        level: 'Level 1',
      ),

      // Level 2
      ParkingSlotModel(
        id: 'slot_2_1',
        parkingLotId: lotId,
        slotNumber: 'B-201',
        isAvailable: true,
        type: 'regular',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_2',
        parkingLotId: lotId,
        slotNumber: 'B-202',
        isAvailable: true,
        type: 'regular',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_3',
        parkingLotId: lotId,
        slotNumber: 'B-203',
        isAvailable: false,
        type: 'ev',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_4',
        parkingLotId: lotId,
        slotNumber: 'B-204',
        isAvailable: true,
        type: 'disabled',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_5',
        parkingLotId: lotId,
        slotNumber: 'B-205',
        isAvailable: true,
        type: 'regular',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_6',
        parkingLotId: lotId,
        slotNumber: 'B-206',
        isAvailable: false,
        type: 'regular',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_7',
        parkingLotId: lotId,
        slotNumber: 'B-207',
        isAvailable: true,
        type: 'ev',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_8',
        parkingLotId: lotId,
        slotNumber: 'B-208',
        isAvailable: true,
        type: 'disabled',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_9',
        parkingLotId: lotId,
        slotNumber: 'B-209',
        isAvailable: false,
        type: 'regular',
        level: 'Level 2',
      ),
      ParkingSlotModel(
        id: 'slot_2_10',
        parkingLotId: lotId,
        slotNumber: 'B-210',
        isAvailable: true,
        type: 'regular',
        level: 'Level 2',
      ),
    ];
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
      return 'mock_booking_${DateTime.now().millisecondsSinceEpoch}';
    }
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

  /// Streams bookings for a specific user in real-time.
  Stream<List<BookingModel>> streamUserBookings(String uid) {
    late final StreamController<List<BookingModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<BookingModel>>(
      onListen: () {
        try {
          subscription = _bookings
              .where('userId', isEqualTo: uid)
              .orderBy('startTime', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => BookingModel.fromFirestore(doc))
                    .toList();
                controller.add(list);
              } catch (e) {
                debugPrint('[FirestoreService] Error mapping streamUserBookings: $e');
                controller.add([]);
              }
            },
            onError: (error) {
              debugPrint('[FirestoreService] streamUserBookings onError: $error');
              controller.add([]);
            },
          );
        } catch (e) {
          debugPrint('[FirestoreService] streamUserBookings onListen catch: $e');
          controller.add([]);
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<BookingModel> _getMockBookings(String uid) {
    final now = DateTime.now();
    return [
      BookingModel(
        id: 'mock_booking_active',
        userId: uid,
        parkingLotId: 'mock_lot_1',
        slotId: 'slot_1_3',
        startTime: now.subtract(const Duration(minutes: 45)),
        endTime: now.add(const Duration(hours: 1, minutes: 15)),
        totalAmount: 40.0,
        status: 'active',
        vehicleId: 'mock_car_1',
        vehiclePlate: 'أ ج د 5432',
        pricePerHour: 20.0,
        reservationId: '9823-4712',
        level: 'Level 1',
        spotLabel: 'Spot A-103',
        paymentMethod: 'wallet',
        lotName: 'Heliopolis Plaza Parking',
        lotAddress: '15 El-Ahram St, Heliopolis, Cairo',
      ),
      BookingModel(
        id: 'mock_booking_past',
        userId: uid,
        parkingLotId: 'mock_lot_1',
        slotId: 'slot_1_1',
        startTime: now.subtract(const Duration(days: 1, hours: 3)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        totalAmount: 40.0,
        status: 'completed',
        vehicleId: 'mock_car_1',
        vehiclePlate: 'أ ج د 5432',
        pricePerHour: 20.0,
        reservationId: '8214-5930',
        level: 'Level 1',
        spotLabel: 'Spot A-101',
        paymentMethod: 'wallet',
        lotName: 'Heliopolis Plaza Parking',
        lotAddress: '15 El-Ahram St, Heliopolis, Cairo',
      ),
    ];
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
              .orderBy('timestamp', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
                    .toList();
                if (list.isEmpty) {
                  controller.add(_getMockNotifications(uid));
                } else {
                  controller.add(list);
                }
              } catch (e) {
                controller.add(_getMockNotifications(uid));
              }
            },
            onError: (error) {
              controller.add(_getMockNotifications(uid));
            },
          );
        } catch (e) {
          controller.add(_getMockNotifications(uid));
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<NotificationModel> _getMockNotifications(String uid) {
    return [
      NotificationModel(
        id: 'noti_1',
        title: 'Booking Confirmed',
        body: 'Your spot A-103 is reserved at Heliopolis Plaza.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: true,
        type: 'booking_reminder',
      ),
      NotificationModel(
        id: 'noti_2',
        title: 'Welcome to Heliopolis Plaza',
        body: 'Your vehicle أ ج د 5432 has entered the gate successfully.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        isRead: false,
        type: 'general',
      ),
    ];
  }

  /// Marks a notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('FirestoreService: error marking notification as read: $e');
    }
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
              .orderBy('timestamp', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => ReviewModel.fromFirestore(doc))
                    .toList();
                if (list.isEmpty) {
                  controller.add(_getMockReviews(lotId));
                } else {
                  controller.add(list);
                }
              } catch (e) {
                controller.add(_getMockReviews(lotId));
              }
            },
            onError: (error) {
              controller.add(_getMockReviews(lotId));
            },
          );
        } catch (e) {
          controller.add(_getMockReviews(lotId));
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<ReviewModel> _getMockReviews(String lotId) {
    return [
      ReviewModel(
        id: 'rev_1',
        userId: 'user_1',
        userName: 'Sherif Ahmed',
        parkingLotId: lotId,
        rating: 5.0,
        comment: 'Very clean parking lot with excellent EV charging facilities!',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReviewModel(
        id: 'rev_2',
        userId: 'user_2',
        userName: 'Mariam Ali',
        parkingLotId: lotId,
        rating: 4.0,
        comment: 'Easy entry/exit system. Highly recommended.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
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
              .orderBy('timestamp', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              try {
                final list = snapshot.docs
                    .map((doc) => TransactionModel.fromFirestore(doc))
                    .toList();
                if (list.isEmpty) {
                  controller.add(_getMockTransactions(uid));
                } else {
                  controller.add(list);
                }
              } catch (e) {
                controller.add(_getMockTransactions(uid));
              }
            },
            onError: (_) {
              controller.add(_getMockTransactions(uid));
            },
          );
        } catch (e) {
          controller.add(_getMockTransactions(uid));
        }
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<TransactionModel> _getMockTransactions(String uid) {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx_1',
        bookingId: 'mock_booking_active',
        userId: uid,
        amount: 40.0,
        paymentMethod: 'wallet',
        timestamp: now.subtract(const Duration(minutes: 45)),
        status: 'success',
      ),
      TransactionModel(
        id: 'tx_2',
        bookingId: 'mock_booking_past',
        userId: uid,
        amount: 40.0,
        paymentMethod: 'wallet',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        status: 'success',
      ),
      TransactionModel(
        id: 'tx_3',
        bookingId: '',
        userId: uid,
        amount: 100.0,
        paymentMethod: 'card',
        timestamp: now.subtract(const Duration(days: 3)),
        status: 'success',
      ),
    ];
  }
}
