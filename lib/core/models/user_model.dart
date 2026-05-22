import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? licenseNumber;
  final String? licenseExpiry;
  final String? licenseCategory;
  final bool licenseVerified;
  final String age;
  final String gender;
  final String address;
  final String phoneNumber;
  final String? photoUrl;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.licenseNumber,
    this.licenseExpiry,
    this.licenseCategory,
    this.licenseVerified = false,
    required this.age,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    this.photoUrl,
    this.updatedAt,
    this.createdAt,
  });

  /// Creates a [UserModel] from a Firestore [DocumentSnapshot].
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      licenseExpiry: data['licenseExpiry'] ?? '',
      licenseCategory: data['licenseCategory'] ?? '',
      licenseVerified: data['licenseVerified'] ?? false,
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrl: data['photoUrl'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [UserModel] to a [Map] for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'licenseNumber': licenseNumber ?? '',
      'licenseExpiry': licenseExpiry ?? '',
      'licenseCategory': licenseCategory ?? '',
      'licenseVerified': licenseVerified,
      'age': age,
      'gender': gender,
      'address': address,
      'phoneNumber': phoneNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// Creates a copy of this [UserModel] with the given fields replaced by the new values.
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? licenseNumber,
    String? licenseExpiry,
    String? licenseCategory,
    bool? licenseVerified,
    String? age,
    String? gender,
    String? address,
    String? phoneNumber,
    String? photoUrl,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseCategory: licenseCategory ?? this.licenseCategory,
      licenseVerified: licenseVerified ?? this.licenseVerified,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, photoUrl: $photoUrl)';
  }
}
