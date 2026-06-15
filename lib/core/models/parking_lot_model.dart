import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingLotModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final String? imageUrl;

  ParkingLotModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    this.imageUrl,
  });

  factory ParkingLotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParkingLotModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      totalSlots: data['totalSlots'] ?? 0,
      availableSlots: data['availableSlots'] ?? 0,
      pricePerHour: (data['pricePerHour'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'pricePerHour': pricePerHour,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ParkingLotModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? totalSlots,
    int? availableSlots,
    double? pricePerHour,
    String? imageUrl,
  }) {
    return ParkingLotModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalSlots: totalSlots ?? this.totalSlots,
      availableSlots: availableSlots ?? this.availableSlots,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Converts the model to a plain [Map] for passing between screens
  /// (avoids re-fetching from Firestore when navigating to detail views).
  Map<String, dynamic> toMapData() => {
    'name': name,
    'address': address,
    'slots': availableSlots,
    'totalSlots': totalSlots,
    'price': 'EGP ${pricePerHour.toStringAsFixed(0)}/hr',
    'lat': latitude,
    'lng': longitude,
    'image': imageUrl ?? 'assets/images/mall_of_arabia.png',
    'id': id,
  };

  @override
  String toString() {
    return 'ParkingLotModel(id: $id, name: $name, available: $availableSlots/$totalSlots)';
  }
}
