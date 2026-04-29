import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final DateTime timestamp;
  final String status; // 'success', 'failed', 'pending'

  TransactionModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    required this.status,
  });

  /// Creates a [TransactionModel] from a Firestore [DocumentSnapshot].
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  /// Converts the [TransactionModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  /// Creates a copy of this [TransactionModel] with the given fields replaced by the new values.
  TransactionModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? paymentMethod,
    DateTime? timestamp,
    String? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, status: $status)';
  }
}
