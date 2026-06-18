import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// Global error handler that maps raw exceptions to friendly messages
/// and shows a consistent floating SnackBar.
class AppErrorHandler {
  AppErrorHandler._();

  /// Converts a raw [error] into a human-readable string.
  static String parse(dynamic error) {
    final raw = error.toString();

    // Firebase Auth errors
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password. Please try again.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (raw.contains('network-request-failed') ||
        raw.contains('SocketException') ||
        raw.contains('No address associated')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (raw.contains('not-found') || raw.contains('does-not-exist')) {
      return 'The requested resource was not found.';
    }
    if (raw.contains('unavailable') || raw.contains('deadline-exceeded')) {
      return 'Service temporarily unavailable. Please try again.';
    }
    if (raw.contains('cancelled')) {
      return 'Operation was cancelled.';
    }
    if (raw.contains('unauthenticated')) {
      return 'Please sign in to continue.';
    }
    if (raw.contains('already-exists')) {
      return 'This record already exists.';
    }

    // Generic fallback — strip noisy prefixes
    final cleaned = raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '')
        .replaceFirst('[firebase_auth/', '')
        .replaceFirst('[cloud_firestore/', '');

    // If cleaned is still very long or looks like a stack-trace, use generic
    if (cleaned.length > 120 || cleaned.contains('\n')) {
      return 'Something went wrong. Please try again.';
    }

    return cleaned.isNotEmpty ? cleaned : 'Something went wrong. Please try again.';
  }

  /// Shows a floating SnackBar with [AppColors.error] background.
  static void showSnackBar(BuildContext context, dynamic error) {
    final message = parse(error);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a floating SnackBar with [AppColors.secondary] background (success).
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.black, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
