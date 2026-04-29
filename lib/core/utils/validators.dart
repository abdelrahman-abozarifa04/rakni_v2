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
}
