import 'package:cloud_functions/cloud_functions.dart';

/// Singleton service that wraps the three OTP Cloud Functions.
///
/// Usage:
///   final otp = OtpService();
///   await otp.sendVerificationOTP(email: email, uid: uid);
///   final ok = await otp.verifyOTP(email: email, code: code, type: OtpType.verification);
class OtpService {
  OtpService._internal();

  factory OtpService() => instance;

  static final OtpService instance = OtpService._internal();

  /// Cloud Functions region — must match the region used in index.ts.
  static const String _region = 'europe-west1';

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _region);

  // ---------------------------------------------------------------------------
  // sendVerificationOTP
  // ---------------------------------------------------------------------------

  /// Triggers the `sendVerificationOTP` Cloud Function.
  ///
  /// Generates a 6-digit code, stores it in `otps/{email}` with
  /// type = "verification", and emails it to [email].
  ///
  /// Throws [Exception] on failure (network error, function error, etc.).
  Future<void> sendVerificationOTP({
    required String email,
    required String uid,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendVerificationOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
        'uid': uid,
      });

      if (result.data['success'] != true) {
        throw Exception('Failed to send verification OTP.');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (e) {
      throw Exception('Could not send verification email: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // sendPasswordResetOTP
  // ---------------------------------------------------------------------------

  /// Triggers the `sendPasswordResetOTP` Cloud Function.
  ///
  /// Generates a 6-digit code, stores it in `otps/{email}` with
  /// type = "password_reset", and emails it to [email].
  ///
  /// Throws [Exception] on failure.
  Future<void> sendPasswordResetOTP({required String email}) async {
    try {
      final callable = _functions.httpsCallable('sendPasswordResetOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
      });

      if (result.data['success'] != true) {
        throw Exception('Failed to send password reset OTP.');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (e) {
      throw Exception('Could not send password reset email: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // verifyOTP
  // ---------------------------------------------------------------------------

  /// Calls the `verifyOTP` Cloud Function and returns `true` if the
  /// [code] is valid for [email] and the given [type].
  ///
  /// Returns `false` on invalid / expired code (no exception thrown —
  /// callers should show the error message to the user).
  ///
  /// Throws [Exception] only on network / function invocation errors.
  Future<OtpVerifyResult> verifyOTP({
    required String email,
    required String code,
    required OtpType type,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'type': type.value,
      });

      final bool success = result.data['success'] == true;
      final String? error = result.data['error'] as String?;

      return OtpVerifyResult(success: success, error: error);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (e) {
      throw Exception('Could not verify OTP: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        return e.message ?? 'Invalid request data.';
      case 'unauthenticated':
        return 'You must be signed in to perform this action.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'internal':
        return 'A server error occurred. Please try again later.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// The two OTP purposes supported by the backend.
enum OtpType {
  verification('verification'),
  passwordReset('password_reset');

  const OtpType(this.value);

  /// The string value stored in Firestore and sent to Cloud Functions.
  final String value;
}

/// Result returned by [OtpService.verifyOTP].
class OtpVerifyResult {
  const OtpVerifyResult({required this.success, this.error});

  final bool success;

  /// Human-readable error message when [success] is `false`.
  final String? error;
}
