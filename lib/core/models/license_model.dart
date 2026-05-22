/// Structured model for extracted Egyptian driver's license data.
/// All fields are nullable because OCR may fail to read some fields.
class LicenseModel {
  final String? holderNameArabic;
  final String? holderNameEnglish;
  final String? nationalId;
  final String? licenseNumber;
  final String? expiryDate;
  final String? issueDate;
  final String? categories;
  final String? issuingAuthority;

  const LicenseModel({
    this.holderNameArabic,
    this.holderNameEnglish,
    this.nationalId,
    this.licenseNumber,
    this.expiryDate,
    this.issueDate,
    this.categories,
    this.issuingAuthority,
  });

  /// Creates a LicenseModel from the raw JSON map returned by the OCR API.
  /// Handles missing keys gracefully.
  factory LicenseModel.fromOcrJson(Map<String, dynamic> json) {
    return LicenseModel(
      holderNameArabic: _clean(json['holder_name_arabic']),
      holderNameEnglish: _clean(json['holder_name_english']),
      nationalId: _clean(json['national_id']),
      licenseNumber: _clean(json['license_number']),
      expiryDate: _clean(json['expiry_date']),
      issueDate: _clean(json['issue_date']),
      categories: _clean(json['categories']),
      issuingAuthority: _clean(json['issuing_authority']),
    );
  }

  /// Converts to a Map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      if (holderNameArabic != null) 'licenseHolderNameAr': holderNameArabic,
      if (holderNameEnglish != null) 'licenseHolderNameEn': holderNameEnglish,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (expiryDate != null) 'licenseExpiry': expiryDate,
      if (issueDate != null) 'licenseIssueDate': issueDate,
      if (categories != null) 'licenseCategory': categories,
      if (issuingAuthority != null) 'licenseIssuingAuthority': issuingAuthority,
      'licenseVerified': false,
    };
  }

  /// Returns true if the minimum required fields were extracted.
  bool get isUsable =>
      licenseNumber != null &&
      licenseNumber!.isNotEmpty &&
      expiryDate != null &&
      expiryDate!.isNotEmpty;

  static String? _clean(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s == 'null' || s == 'N/A' || s == 'غير متاح' ? null : s;
  }

  @override
  String toString() =>
      'LicenseModel(licenseNumber: $licenseNumber, expiry: $expiryDate, categories: $categories)';
}
