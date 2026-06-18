import 'package:cloud_functions/cloud_functions.dart';
import 'package:rakni_v2/core/utils/firebase_error_mapper.dart';

enum OtpType { signupVerification, passwordReset }

class OtpVerificationResult {
  final bool success;
  final String? error;

  const OtpVerificationResult({required this.success, this.error});
}

class OtpService {
  OtpService._();
  static final instance = OtpService._();

  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<void> sendVerificationOTP({
    required String email,
    required String uid,
  }) async {
    try {
      await _functions.httpsCallable('sendVerificationOTP').call({
        'email': email,
        'uid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(FirebaseErrorMapper.mapFunctionsError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred while sending OTP');
    }
  }

  Future<void> sendPasswordResetOTP({required String email}) async {
    try {
      await _functions.httpsCallable('sendPasswordResetOTP').call({
        'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(FirebaseErrorMapper.mapFunctionsError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred while sending OTP');
    }
  }

  Future<OtpVerificationResult> verifyOTP({
    required String email,
    required String code,
    required OtpType type,
  }) async {
    try {
      final result = await _functions.httpsCallable('verifyOTP').call({
        'email': email,
        'code': code,
        'type': type == OtpType.signupVerification
            ? 'verification'
            : 'password_reset',
      });

      final bool success = result.data['success'] ?? false;
      final String? error = result.data['error'];

      return OtpVerificationResult(success: success, error: error);
    } on FirebaseFunctionsException catch (e) {
      return OtpVerificationResult(
        success: false,
        error: FirebaseErrorMapper.mapFunctionsError(e),
      );
    } catch (e) {
      return OtpVerificationResult(
        success: false,
        error: 'An unexpected error occurred during OTP verification',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _functions.httpsCallable('resetPassword').call({
        'email': email,
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(FirebaseErrorMapper.mapFunctionsError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred while resetting password');
    }
  }
}

