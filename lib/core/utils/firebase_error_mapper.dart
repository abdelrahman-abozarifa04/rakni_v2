import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Centralized translator from raw Firebase Auth / Cloud Functions error
/// codes into short, user-facing English messages.
///
/// IMPORTANT: never surface `e.message` directly to the UI. Firebase's raw
/// messages (e.g. "The supplied auth credential is incorrect, malformed or
/// has expired.", or a literal status string like "NOT_FOUND" when a Cloud
/// Function call fails at the transport level) are not meant for end users.
/// Always map on `e.code` and log the raw error via [debugPrint] so the
/// real cause is still visible in development/Crashlytics logs.
class FirebaseErrorMapper {
  FirebaseErrorMapper._();

  /// Maps a [FirebaseAuthException] to a friendly message.
  static String mapAuthError(FirebaseAuthException e) {
    debugPrint(
      '[FirebaseErrorMapper] Auth error -> code: ${e.code}, message: ${e.message}',
    );

    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'wrong-password':
        return 'Incorrect email or password. Please try again.';
      // Modern Firebase Auth (with email-enumeration protection enabled)
      // returns this single code for BOTH "wrong password" and "no such
      // user", so attackers can't tell which one it is. We show one
      // friendly message covering both cases.
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled.';
      case 'email-not-verified':
        return 'Please verify your email before signing in.';
      case 'expired-action-code':
        return 'This link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This link is invalid or has already been used.';
      default:
        // Never leak raw Firebase internals to the user.
        return 'Something went wrong while signing you in. Please try again.';
    }
  }

  /// Maps a [FirebaseFunctionsException] (thrown by our Cloud Functions
  /// calls — OTP, email verification, password reset) to a friendly
  /// message. We map purely on `e.code` and never trust `e.message`,
  /// because a missing/undeployed function, or a cold-start failure, can
  /// surface as a raw status string (e.g. "NOT_FOUND") in `e.message`.
  ///
  /// Exception: `failed-precondition` is only ever thrown deliberately by
  /// our own functions (see `functions/src/index.ts`) with an already
  /// human-readable message, so it's safe to pass through.
  static String mapFunctionsError(FirebaseFunctionsException e) {
    debugPrint(
      '[FirebaseErrorMapper] Functions error -> code: ${e.code}, '
      'message: ${e.message}, details: ${e.details}',
    );

    switch (e.code) {
      case 'not-found':
        return "We couldn't complete this request right now. Please try "
            'again, and contact support if this keeps happening.';
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      case 'invalid-argument':
        return 'Some information is missing or invalid. Please check and try again.';
      case 'failed-precondition':
        return e.message ?? 'This action cannot be completed right now.';
      case 'deadline-exceeded':
      case 'unavailable':
        return 'Our servers are taking too long to respond. Please try again.';
      case 'resource-exhausted':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'already-exists':
        return 'This already exists.';
      case 'internal':
      default:
        return 'Something went wrong on our end. Please try again, and '
            'contact support if this keeps happening.';
    }
  }
}
