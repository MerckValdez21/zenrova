import 'package:flutter/material.dart';
import '../../core/utils/helpers.dart';
import '../../services/firebase_auth_service.dart';

/// AuthViewModel — Zenrova
/// Manages all authentication state for the app.
/// Implements ChangeNotifier for reactive UI updates.
class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentUserEmail;
  bool _isAuthenticated = false;

  // ── Getters ────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get currentUserEmail => _currentUserEmail;
  bool get isAuthenticated => _isAuthenticated;
  String get userDisplayName => _currentUserEmail?.split('@').first ?? 'Friend';

  // ── State setters ──────────────────────────────────────────────
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? success) {
    _successMessage = success;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Sign in ────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    if (email.trim().isEmpty) {
      _setError('Please enter your email address.');
      return false;
    }
    if (!Helpers.isValidEmail(email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }
    if (password.isEmpty) {
      _setError('Please enter your password.');
      return false;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return false;
    }

    _setLoading(true);
    try {
      final FirebaseAuthService authService = FirebaseAuthService();
      final credential = await authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUserEmail = credential.user?.email;
      _isAuthenticated = true;
      _setSuccess('Welcome back to Zenrova!');
      return true;
    } catch (e) {
      _setError('Sign-in failed. Please check your credentials and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ───────────────────────────────────────────────────
  Future<bool> register(String name, String email, String password) async {
    if (name.trim().isEmpty) {
      _setError('Please enter your name.');
      return false;
    }
    if (!Helpers.isValidEmail(email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }
    if (password.length < 8) {
      _setError('Password must be at least 8 characters.');
      return false;
    }

    _setLoading(true);
    try {
      final FirebaseAuthService authService = FirebaseAuthService();
      final credential = await authService.registerWithEmailAndPassword(
        email: email.trim(),
        password: password,
        displayName: name.trim(),
      );
      _currentUserEmail = credential.user?.email;
      _isAuthenticated = true;
      _setSuccess('Welcome to Zenrova, ${Helpers.truncateText(name.trim(), 20)}!');
      return true;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Reset password ─────────────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    if (!Helpers.isValidEmail(email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }

    _setLoading(true);
    try {
      final FirebaseAuthService authService = FirebaseAuthService();
      await authService.resetPassword(email.trim());
      _setSuccess('Reset link sent to ${email.trim()}. Check your inbox.');
      return true;
    } catch (e) {
      _setError('Could not send reset email. Try again later.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google sign-in (not yet implemented) ───────────────────────
  Future<bool> signInWithGoogle(String googleEmail) async {
    if (!Helpers.isValidEmail(googleEmail.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }

    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      _currentUserEmail = googleEmail.trim();
      _isAuthenticated = true;
      _setSuccess('Signed in with Google successfully!');
      return true;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Guest ──────────────────────────────────────────────────────
  void continueAsGuest() {
    _currentUserEmail = null;
    _isAuthenticated = true;
    _setSuccess('Continuing as guest');
  }

  // ── Sign out ───────────────────────────────────────────────────
  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUserEmail = null;
    clearMessages();
    await FirebaseAuthService().signOut();
  }

  // ── Helpers ────────────────────────────────────────────────────
  void showAuthSnackBar(BuildContext context, {bool isError = false}) {
    final message = isError ? _errorMessage : _successMessage;
    if (message == null) return;
    Helpers.showSnackBar(
      context,
      message,
      color: isError ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
    );
  }
}