// ignore_for_file: constant_identifier_names

enum SubscriptionType {
  MONTHLY,
  QUARTERLY,
  YEARLY;

  String toJson() => name;

  static SubscriptionType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'QUARTERLY':
        return SubscriptionType.QUARTERLY;
      case 'YEARLY':
        return SubscriptionType.YEARLY;
      case 'MONTHLY':
      default:
        return SubscriptionType.MONTHLY;
    }
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double pricePerMonth;
  final double dailyRate;
  final int durationDays;
  final String description;
  final List<String> features;
  final SubscriptionType type;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.dailyRate,
    required this.durationDays,
    required this.description,
    required this.features,
    required this.type,
  });
}

class Subscription {
  final int id;
  final String plateNumber;
  final String customerName;
  final String email;
  final String phone;
  final SubscriptionType subscriptionType;
  final bool unlimitedEntries;
  final int monthlyLimit;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyFee;
  final bool isActive;
  final bool isValid;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.plateNumber,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.subscriptionType,
    required this.unlimitedEntries,
    required this.monthlyLimit,
    required this.startDate,
    required this.endDate,
    required this.monthlyFee,
    required this.isActive,
    required this.isValid,
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int? ?? 0,
      plateNumber: json['plate_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      subscriptionType: SubscriptionType.fromString(json['subscription_type'] as String? ?? 'MONTHLY'),
      unlimitedEntries: json['unlimited_entries'] as bool? ?? false,
      monthlyLimit: json['monthly_limit'] as int? ?? 0,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ?? DateTime.now(),
      monthlyFee: double.tryParse(json['monthly_fee']?.toString() ?? '') ?? 0.0,
      isActive: json['is_active'] as bool? ?? false,
      isValid: json['is_valid'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plate_number': plateNumber,
      'customer_name': customerName,
      'email': email,
      'phone': phone,
      'subscription_type': subscriptionType.toJson(),
      'unlimited_entries': unlimitedEntries,
      'monthly_limit': monthlyLimit,
      'start_date': "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
      'end_date': "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
      'monthly_fee': monthlyFee.toStringAsFixed(2),
      'is_active': isActive,
    };
  }
}
