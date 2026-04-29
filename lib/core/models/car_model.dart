import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String uid; // Typically matches the User UID
  final String plateNumber;
  final String carModel;
  final String carColor;
  final String manufacturingYear;
  final DateTime? updatedAt;

  CarModel({
    required this.uid,
    required this.plateNumber,
    required this.carModel,
    required this.carColor,
    required this.manufacturingYear,
    this.updatedAt,
  });

  /// Creates a [CarModel] from a Firestore [DocumentSnapshot].
  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CarModel(
      uid: doc.id,
      plateNumber: data['plateNumber'] ?? '',
      carModel: data['carModel'] ?? '',
      carColor: data['carColor'] ?? '',
      manufacturingYear: data['manufacturingYear'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [CarModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'plateNumber': plateNumber,
      'carModel': carModel,
      'carColor': carColor,
      'manufacturingYear': manufacturingYear,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Creates a copy of this [CarModel] with the given fields replaced by the new values.
  CarModel copyWith({
    String? uid,
    String? plateNumber,
    String? carModel,
    String? carColor,
    String? manufacturingYear,
    DateTime? updatedAt,
  }) {
    return CarModel(
      uid: uid ?? this.uid,
      plateNumber: plateNumber ?? this.plateNumber,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CarModel(uid: $uid, plateNumber: $plateNumber, carModel: $carModel)';
  }
}
