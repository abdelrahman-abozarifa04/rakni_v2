/// Centralized form-field validators for the Rakni app.
///
/// All [validate*] methods follow the Flutter [FormFieldValidator<String>]
/// signature — they return `null` when the value is valid, or a non-null
/// error string when it is not.
class Validators {
  // Private constructor — this class is not meant to be instantiated.
  Validators._();

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  /// Returns `null` if [value] is a non-empty string containing `@`,
  /// otherwise returns an error message.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!value.trim().contains('@')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  /// Returns `null` if [value] is a non-empty string with at least 8
  /// characters, otherwise returns an error message.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Generic required field
  // ---------------------------------------------------------------------------

  /// Returns `null` if [value] is non-empty, otherwise returns
  /// `"<fieldName> is required."`.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password confirmation
  // ---------------------------------------------------------------------------

  /// Returns `true` if [password] and [confirm] are identical, `false`
  /// otherwise.
  static bool passwordsMatch(String password, String confirm) {
    return password == confirm;
  }

  /// Validates Egyptian driver's license number (6-8 digits).
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required.';
    }
    final digitsOnly = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 6 || digitsOnly.length > 8) {
      return 'License number must be 6-8 digits.';
    }
    return null;
  }

  /// Validates Egyptian license plate format.
  ///
  /// Accepts Arabic letters + Arabic/Western digits, or Latin letters + digits.
  static String? validateEgyptianPlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required.';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.length < 5 || cleaned.length > 8) {
      return 'Plate number must be 5-8 characters (e.g., أبج1234 or ABC1234).';
    }
    final arabicPlate = RegExp(
      r'^[\u0621-\u064A]{1,3}[0-9\u0660-\u0669]{3,4}$',
    );
    final latinPlate = RegExp(r'^[A-Za-z]{1,3}[0-9]{3,4}$');
    if (!arabicPlate.hasMatch(cleaned) && !latinPlate.hasMatch(cleaned)) {
      return 'Invalid plate format. Use format: أبج1234 or ABC1234.';
    }
    return null;
  }

  /// Validates Egyptian license expiry date (DD/MM/YYYY) and checks not expired.
  static String? validateLicenseExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required.';
    }
    final parts = value.trim().split('/');
    if (parts.length != 3) return 'Use format DD/MM/YYYY.';
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final expiry = DateTime(year, month, day);
      if (expiry.day != day || expiry.month != month || expiry.year != year) {
        return 'Invalid date. Use format DD/MM/YYYY.';
      }
      if (expiry.isBefore(DateTime.now())) {
        return 'License is expired. Please renew before registering.';
      }
    } catch (_) {
      return 'Invalid date. Use format DD/MM/YYYY.';
    }
    return null;
  }
}
