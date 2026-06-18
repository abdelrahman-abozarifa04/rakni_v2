import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/auth_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/auth/create_account_step3_screen.dart';
import 'package:rakni_v2/core/utils/firebase_error_mapper.dart';

class CreateAccountStep2Screen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const CreateAccountStep2Screen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<CreateAccountStep2Screen> createState() =>
      _CreateAccountStep2ScreenState();
}

class _CreateAccountStep2ScreenState extends State<CreateAccountStep2Screen> {
  // ── state ──────────────────────────────────────────────────────────────
  String? _uid;
  bool _isSending = false;
  bool _isChecking = false;

  /// Countdown before the "Resend" button becomes active (seconds).
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  /// Polls Firebase every 4 s to detect emailVerified == true.
  Timer? _pollTimer;

  // ── lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _createUserAndSendLink();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────
  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _checkEmailVerified();
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── core logic ─────────────────────────────────────────────────────────

  /// Creates the Firebase Auth user (or re-uses an existing one) then sends
  /// the verification e-mail and begins polling.
  Future<void> _createUserAndSendLink() async {
    setState(() => _isSending = true);

    UserCredential? cred;

    // Step A — create (or recover) the Firebase Auth account. Any failure
    // here means no usable account exists yet, so it's safe to pop back to
    // Step 1.
    try {
      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );
        await cred.user?.updateDisplayName(widget.fullName);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account already exists — try to sign in with the same password
          // so the user can resume verification without re-entering anything.
          try {
            cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: widget.email,
              password: widget.password,
            );
          } on FirebaseAuthException {
            if (!mounted) return;
            _showSnackBar(
              'An account with this email already exists with a different '
              'password. Please go back and sign in instead.',
            );
            Navigator.pop(context);
            if (mounted) setState(() => _isSending = false);
            return;
          }
        } else {
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(FirebaseErrorMapper.mapAuthError(e));
      Navigator.pop(context);
      if (mounted) setState(() => _isSending = false);
      return;
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not create your account. Please try again.');
      Navigator.pop(context);
      if (mounted) setState(() => _isSending = false);
      return;
    }

    _uid = cred.user?.uid;

    // If already verified somehow, skip straight to Step 3.
    if (cred.user?.emailVerified == true) {
      if (mounted) setState(() => _isSending = false);
      _navigateToStep3();
      return;
    }

    // Step B — the account now exists, so from here on we NEVER pop this
    // screen on failure. Losing the account reference would force the user
    // all the way back to Step 1 for no reason — instead we stay here and
    // let them retry sending the email.
    await _sendVerificationEmailWithFeedback();
  }

  /// Sends the verification email and reports the result inline on THIS
  /// screen instead of bubbling a generic error and popping back to Step 1.
  Future<void> _sendVerificationEmailWithFeedback() async {
    try {
      await _sendVerificationEmail(FirebaseAuth.instance.currentUser);
      _startCooldown();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      // Make the "Resend" button available immediately — don't leave the
      // user stuck behind a frozen 60s cooldown when nothing was actually
      // sent.
      setState(() => _resendCooldown = 0);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendVerificationEmail(User? user) async {
    if (user == null) return;
    await AuthService.instance.sendEmailVerification();
  }

  /// Reloads the Firebase user and navigates to Step 3 if verified.
  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        _pollTimer?.cancel();
        _navigateToStep3();
      }
    } catch (_) {
      // Silently ignore transient network errors — the timer will retry.
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _navigateToStep3() {
    if (!mounted || _uid == null) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAccountStep3Screen(
          uid: _uid!,
          fullName: widget.fullName,
          email: widget.email,
        ),
      ),
      (route) => false,
    );
  }

  /// Manual "Resend" button handler.
  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isSending) return;
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Your session expired. Please go back and sign up again.');
        return;
      }
      await _sendVerificationEmail(user);
      _startCooldown();
      _showSnackBar('Verification email sent! Please check your inbox.', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Lets the user manually trigger the verified check instead of waiting.
  Future<void> _manualCheck() async {
    await _checkEmailVerified();
    if (mounted &&
        !(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
      _showSnackBar('Email not verified yet. Please check your inbox.');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 20,
          ),
          label: Text(
            'Back',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 24),
                    Text(
                      'Verify Email',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Step 2 of 3',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),

                    // ── progress bar ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _progressSegment(filled: true)),
                        SizedBox(width: 8),
                        Expanded(child: _progressSegment(filled: true)),
                        SizedBox(width: 8),
                        Expanded(child: _progressSegment(filled: false)),
                      ],
                    ),
                    SizedBox(height: 48),

                    // ── email icon ────────────────────────────────────
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          color: AppColors.secondary,
                          size: 44,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // ── description ───────────────────────────────────
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'We sent a verification link to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Click the link in the email to verify your account. This page will update automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 32),

                    // ── polling indicator ─────────────────────────────
                    if (_isChecking)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Checking…',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),

                    // ── resend section ────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _resendCooldown > 0
                                ? 'Resend link in ${_resendCooldown}s'
                                : "Didn't receive the email?",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (_resendCooldown == 0)
                            TextButton(
                              onPressed: _isSending ? null : _resendEmail,
                              child: _isSending
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.secondary,
                                      ),
                                    )
                                  : Text(
                                      'Resend Link',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── bottom button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: (_isSending || _uid == null) ? null : _manualCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isChecking
                    ? CircularProgressIndicator(color: AppColors.black)
                    : Text(
                        "I've verified my email",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressSegment({required bool filled}) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: filled ? AppColors.secondary : AppColors.fieldStroke,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
