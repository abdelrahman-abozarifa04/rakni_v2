import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String parkingLotId;
  final String slotId;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalAmount;
  final String status; // 'pending', 'active', 'completed', 'cancelled'

  // Extended fields for booking/session lifecycle
  final String vehicleId;
  final String vehiclePlate;
  final double pricePerHour;
  final String reservationId; // e.g., "4563-8520"
  final String level;         // e.g., "Level 2"
  final String spotLabel;     // e.g., "Spot A-234"
  final String paymentMethod; // e.g., "wallet", "visa"
  final String lotName;       // denormalized for quick display
  final String lotAddress;    // denormalized for quick display

  BookingModel({
    required this.id,
    required this.userId,
    required this.parkingLotId,
    required this.slotId,
    required this.startTime,
    this.endTime,
    required this.totalAmount,
    required this.status,
    this.vehicleId = '',
    this.vehiclePlate = '',
    this.pricePerHour = 0.0,
    this.reservationId = '',
    this.level = '',
    this.spotLabel = '',
    this.paymentMethod = '',
    this.lotName = '',
    this.lotAddress = '',
  });

  /// Creates a [BookingModel] from a Firestore [DocumentSnapshot].
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      parkingLotId: data['parkingLotId'] ?? '',
      slotId: data['slotId'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      vehicleId: data['vehicleId'] ?? '',
      vehiclePlate: data['vehiclePlate'] ?? '',
      pricePerHour: (data['pricePerHour'] ?? 0.0).toDouble(),
      reservationId: data['reservationId'] ?? '',
      level: data['level'] ?? '',
      spotLabel: data['spotLabel'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      lotName: data['lotName'] ?? '',
      lotAddress: data['lotAddress'] ?? '',
    );
  }

  /// Converts the [BookingModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'parkingLotId': parkingLotId,
      'slotId': slotId,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'totalAmount': totalAmount,
      'status': status,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'pricePerHour': pricePerHour,
      'reservationId': reservationId,
      'level': level,
      'spotLabel': spotLabel,
      'paymentMethod': paymentMethod,
      'lotName': lotName,
      'lotAddress': lotAddress,
    };
  }

  /// Creates a copy of this [BookingModel] with the given fields replaced by the new values.
  BookingModel copyWith({
    String? id,
    String? userId,
    String? parkingLotId,
    String? slotId,
    DateTime? startTime,
    DateTime? endTime,
    double? totalAmount,
    String? status,
    String? vehicleId,
    String? vehiclePlate,
    double? pricePerHour,
    String? reservationId,
    String? level,
    String? spotLabel,
    String? paymentMethod,
    String? lotName,
    String? lotAddress,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parkingLotId: parkingLotId ?? this.parkingLotId,
      slotId: slotId ?? this.slotId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      reservationId: reservationId ?? this.reservationId,
      level: level ?? this.level,
      spotLabel: spotLabel ?? this.spotLabel,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lotName: lotName ?? this.lotName,
      lotAddress: lotAddress ?? this.lotAddress,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  /// Duration of the booking (null if endTime not set).
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  @override
  String toString() {
    return 'BookingModel(id: $id, userId: $userId, status: $status, reservationId: $reservationId)';
  }
}
