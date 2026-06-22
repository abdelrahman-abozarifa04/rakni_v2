/// Represents a blacklist status from the Django API.
class BlacklistStatus {
  final int id;
  final String plateNumber;
  final String reason;
  final DateTime addedDate;
  final String addedBy;
  final bool isActive;
  final DateTime createdAt;

  BlacklistStatus({
    required this.id,
    required this.plateNumber,
    required this.reason,
    required this.addedDate,
    required this.addedBy,
    required this.isActive,
    required this.createdAt,
  });

  factory BlacklistStatus.fromJson(Map<String, dynamic> json) {
    return BlacklistStatus(
      id: json['id'] as int? ?? 0,
      plateNumber: json['plate_number'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      addedDate: DateTime.tryParse(json['added_date'] as String? ?? '') ?? DateTime.now(),
      addedBy: json['added_by'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
