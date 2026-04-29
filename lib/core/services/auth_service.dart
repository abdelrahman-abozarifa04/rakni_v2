import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rakni_v2/core/services/otp_service.dart';

/// Singleton service that wraps [FirebaseAuth] and [GoogleSignIn].
///
/// Usage:
///   final auth = AuthService.instance;
///   final cred = await auth.signInWithEmailAndPassword(email, password);
class AuthService {
  AuthService._internal();

  factory AuthService() => instance;

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  /// Creates a new user account with [email] and [password].
  ///
  /// After account creation, sends a 6-digit OTP to [email] via Cloud Functions
  /// instead of Firebase's default link-based verification email.
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Immediately send a 6-digit OTP so the user can verify via code entry.
      if (credential.user != null) {
        await OtpService().sendVerificationOTP(
          email: email,
          uid: credential.user!.uid,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Email verification (OTP-based)
  // ---------------------------------------------------------------------------

  /// Resends a 6-digit verification OTP to the currently signed-in user's email.
  ///
  /// Throws an [Exception] if there is no authenticated user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception(
        'No signed-in user found. Cannot send verification OTP.',
      );
    }
    await OtpService().sendVerificationOTP(
      email: user.email!,
      uid: user.uid,
    );
  }

  // ---------------------------------------------------------------------------
  // Password reset (OTP-based)
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit password-reset OTP to [email] via Cloud Functions.
  ///
  /// The caller should then present an OTP input screen, call
  /// [OtpService().verifyOTP] with type [OtpType.passwordReset], and on
  /// success prompt the user to set a new password.
  Future<void> sendPasswordResetEmail(String email) async {
    await OtpService().sendPasswordResetOTP(email: email);
  }

  /// Updates the password of the currently signed-in user.
  ///
  /// Call this AFTER [OtpService.verifyOTP] returns success for a
  /// password_reset OTP.
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
  // State accessors
  // ---------------------------------------------------------------------------

  /// Returns the currently signed-in [User], or `null` if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// A stream that emits a [User] whenever the Firebase auth state changes.
  /// Emits `null` when the user signs out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
