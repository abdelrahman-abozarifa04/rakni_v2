import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String brand;
  final String plateNumber;
  final String model;
  final String color;
  final bool isDefault;
  final DateTime? createdAt;

  VehicleModel({
    required this.id,
    required this.brand,
    required this.plateNumber,
    required this.model,
    required this.color,
    required this.isDefault,
    this.createdAt,
  });

  /// Creates a [VehicleModel] from a Firestore [DocumentSnapshot].
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VehicleModel(
      id: doc.id,
      brand: data['brand'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      model: data['model'] ?? '',
      color: data['color'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [VehicleModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'plateNumber': plateNumber,
      'model': model,
      'color': color,
      'isDefault': isDefault,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// Creates a copy of this [VehicleModel] with the given fields replaced by the new values.
  VehicleModel copyWith({
    String? id,
    String? brand,
    String? plateNumber,
    String? model,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'VehicleModel(id: $id, brand: $brand, plateNumber: $plateNumber, isDefault: $isDefault)';
  }
}
