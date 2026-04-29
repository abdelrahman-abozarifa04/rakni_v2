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

  BookingModel({
    required this.id,
    required this.userId,
    required this.parkingLotId,
    required this.slotId,
    required this.startTime,
    this.endTime,
    required this.totalAmount,
    required this.status,
  });

  /// Creates a [BookingModel] from a Firestore [DocumentSnapshot].
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      parkingLotId: data['parkingLotId'] ?? '',
      slotId: data['slotId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
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
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, userId: $userId, status: $status)';
  }
}
