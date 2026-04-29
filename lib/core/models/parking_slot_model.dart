import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotModel {
  final String id;
  final String parkingLotId;
  final String slotNumber;
  final bool isAvailable;
  final String type; // e.g., 'regular', 'disabled', 'ev'

  ParkingSlotModel({
    required this.id,
    required this.parkingLotId,
    required this.slotNumber,
    required this.isAvailable,
    required this.type,
  });

  /// Creates a [ParkingSlotModel] from a Firestore [DocumentSnapshot].
  factory ParkingSlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParkingSlotModel(
      id: doc.id,
      parkingLotId: data['parkingLotId'] ?? '',
      slotNumber: data['slotNumber'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      type: data['type'] ?? 'regular',
    );
  }

  /// Converts the [ParkingSlotModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'parkingLotId': parkingLotId,
      'slotNumber': slotNumber,
      'isAvailable': isAvailable,
      'type': type,
    };
  }

  /// Creates a copy of this [ParkingSlotModel] with the given fields replaced by the new values.
  ParkingSlotModel copyWith({
    String? id,
    String? parkingLotId,
    String? slotNumber,
    bool? isAvailable,
    String? type,
  }) {
    return ParkingSlotModel(
      id: id ?? this.id,
      parkingLotId: parkingLotId ?? this.parkingLotId,
      slotNumber: slotNumber ?? this.slotNumber,
      isAvailable: isAvailable ?? this.isAvailable,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'ParkingSlotModel(id: $id, slot: $slotNumber, available: $isAvailable)';
  }
}
