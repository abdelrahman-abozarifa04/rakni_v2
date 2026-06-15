import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that wraps [FirebaseAuth] and [GoogleSignIn].
///
/// Usage:
///   final auth = AuthService.instance;
///   final cred = await auth.signInWithEmailAndPassword(email, password);
class AuthService {
  AuthService._internal();

  factory AuthService() => instance;

  static final AuthService instance = AuthService._internal();

  // Web Client ID from Firebase Console > Authentication > Sign-in method > Google.
  // Sourced from android/app/google-services.json oauth_client with client_type: 3
  static const String _webClientId =
      '863311891829-1fmt6ipr4h6vo1efrbjp1j4vromn9gnj.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  /// Maps common [FirebaseAuthException] error codes to readable messages and
  /// rethrows as a plain [Exception] so callers don't need to import firebase_auth.
  Exception _handleAuthError(FirebaseAuthException e) {
    final String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found for this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account with this email already exists.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'email-not-verified':
        message = 'Please verify your email before signing in.';
        break;
      default:
        message = e.message ?? 'An authentication error occurred.';
    }
    return Exception(message);
  }

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with [email] and [password].
  ///
  /// Throws [Exception('email-not-verified')] if the user's email has not been
  /// verified yet (and signs them out first so they cannot access the app).
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && !credential.user!.emailVerified) {
        await _auth.signOut();
        throw _handleAuthError(
          FirebaseAuthException(code: 'email-not-verified'),
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sends a verification email to the user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No signed-in user. Cannot send verification email.');
    }
    try {
      await _functions.httpsCallable('sendVerificationEmailLink').call({
        'email': user.email,
        'uid': user.uid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to send verification email.');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Immediately send a custom verification email via SendGrid.
      if (credential.user != null) {
        await sendEmailVerification();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  /// Sends a native Firebase password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _functions.httpsCallable('sendPasswordResetEmailLink').call({
        'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to send password reset email.');
    }
  }

  /// Updates the password of the currently signed-in user.
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No signed-in user. Cannot update password.');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Performs a full Google Sign-In flow and authenticates with Firebase.
  ///
  /// Returns the resulting [UserCredential] on success.
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 1. Open the Google account picker.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user cancelled the sign-in dialog.
        throw Exception('Google sign-in was cancelled by the user.');
      }

      // 2. Obtain the auth tokens from the selected Google account.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Build a Firebase credential from the Google tokens.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential.
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Signs out from FirebaseAuth and, if active, from GoogleSignIn as well.
  Future<void> signOut() async {
    try {
      // Sign out from Google first (if the user signed in via Google).
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Email Link Auth
  // ---------------------------------------------------------------------------

  static const String _emailKey = 'user_email_for_auth';

  /// Sends a sign-in/verification link to [email].
  Future<void> sendSignInWithEmailLink(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url:
            'https://rakni-v2.firebaseapp.com', // استخدام نطاق Hosting بدلاً من page.link
        handleCodeInApp: true,
        androidPackageName: 'com.rakniteam.rakni_v2',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Save email locally to complete sign-in without asking user again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Checks if the given [link] is a valid sign-in with email link.
  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  /// Completes the sign-in/verification using the [link].
  /// Tries to get the email from SharedPreferences if not provided.
  Future<UserCredential> signInWithEmailLink(
    String link, {
    String? email,
  }) async {
    try {
      String? finalEmail = email;

      if (finalEmail == null) {
        final prefs = await SharedPreferences.getInstance();
        finalEmail = prefs.getString(_emailKey);
      }

      if (finalEmail == null) {
        throw Exception(
          'Email not found. Please provide the email used for the sign-in link.',
        );
      }

      final credential = await _auth.signInWithEmailLink(
        email: finalEmail,
        emailLink: link,
      );

      // Clear the saved email after successful sign-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // State accessors
  // ---------------------------------------------------------------------------

  /// Returns the currently signed-in [User], or `null` if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// A stream that emits a [User] whenever the Firebase auth state changes.
  /// Emits `null` when the user signs out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Reloads the current user to get the latest emailVerified status.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}
