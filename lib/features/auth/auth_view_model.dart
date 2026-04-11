import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/helpers.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../shared/models/user_model.dart';

/// AuthViewModel — Zenrova
/// Manages all authentication state for the app.
class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentUserEmail;
  bool _isAuthenticated = false;

  // Demo mode for live presentation - disabled for real users
  static const bool _demoMode = false;
  
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Demo users for presentation
  static const Map<String, String> _demoUsers = {
    'john@demo.com': 'password123',
    'sarah@demo.com': 'password123',
    'mike@demo.com': 'password123',
    'admin@demo.com': 'admin123',
  };

  // ── Getters ────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get currentUserEmail => _currentUserEmail;
  bool get isAuthenticated => _isAuthenticated;
  String get userDisplayName =>
      _currentUserEmail?.split('@').first ?? 'Friend';

  // ── State helpers ──────────────────────────────────────────────
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

  // ── Load user from Firestore and set into UserProvider ─────────
  Future<void> _loadAndSetUser(
      BuildContext context, String uid, String email, String displayName) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Demo mode - create user locally without Firestore
    if (_demoMode) {
      final demoUser = UserModel(
        id: uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: true,
        isAdmin: email.contains('admin'), // Make admin users with 'admin' in email
      );
      userProvider.setUser(demoUser);
      return;
    }

    // Firebase mode (original code)
    try {
      UserModel? existingUser = await _firestoreService.getUser(uid);

      if (existingUser != null) {
        userProvider.setUser(existingUser);
        final updated = existingUser.copyWith(lastLoginAt: DateTime.now());
        await _firestoreService.updateUser(updated);
        userProvider.setUser(updated);
      } else {
        final newUser = UserModel(
          id: uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: true,
          isAdmin: false,
        );
        await _firestoreService.createUser(newUser);
        userProvider.setUser(newUser);
      }
    } catch (e) {
      debugPrint('Failed to load user from Firestore: $e');
      final fallbackUser = UserModel(
        id: uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: true,
        isAdmin: false,
      );
      userProvider.setUser(fallbackUser);
    }
  }

  // ── Sign in ────────────────────────────────────────────────────
  Future<bool> signIn(
      BuildContext context, String email, String password) async {
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

    _setLoading(true);
    
    // Demo mode for live presentation
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      final trimmedEmail = email.trim().toLowerCase();
      if (_demoUsers.containsKey(trimmedEmail) && _demoUsers[trimmedEmail] == password) {
        // Create demo user
        final uid = 'demo_${trimmedEmail.replaceAll('@', '_').replaceAll('.', '_')}';
        final displayName = trimmedEmail.split('@').first;
        
        if (context.mounted) {
          await _loadAndSetUser(context, uid, trimmedEmail, displayName);
        }
        
        _currentUserEmail = trimmedEmail;
        _isAuthenticated = true;
        _setSuccess('Welcome back to Zenrova!');
        return true;
      } else {
        _setError('Invalid demo credentials. Try: john@demo.com / password123');
        return false;
      }
    }
    
    // Firebase mode (original code)
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final userEmail = credential.user?.email ?? email.trim();
      final displayName =
          credential.user?.displayName ?? email.split('@').first;

      if (context.mounted) {
        await _loadAndSetUser(context, uid, userEmail, displayName);
      }

      _currentUserEmail = userEmail;
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
  Future<bool> register(
      BuildContext context, String name, String email, String password) async {
    if (name.trim().isEmpty) {
      _setError('Please enter your name.');
      return false;
    }
    if (!Helpers.isValidEmail(email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return false;
    }

    _setLoading(true);
    
    // Demo mode for live presentation
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network delay
      
      final trimmedEmail = email.trim().toLowerCase();
      
      // Check if email already exists in demo users
      if (_demoUsers.containsKey(trimmedEmail)) {
        _setError('This email is already registered. Try signing in instead.');
        return false;
      }
      
      // Create new demo user
      final uid = 'demo_${trimmedEmail.replaceAll('@', '_').replaceAll('.', '_')}';
      
      if (context.mounted) {
        await _loadAndSetUser(context, uid, trimmedEmail, name.trim());
      }
      
      _currentUserEmail = trimmedEmail;
      _isAuthenticated = true;
      _setSuccess('Welcome to Zenrova, ${Helpers.truncateText(name.trim(), 20)}!');
      return true;
    }
    
    // Firebase mode (original code)
    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email.trim(),
        password: password,
        displayName: name.trim(),
      );

      final uid = credential.user!.uid;
      final userEmail = credential.user?.email ?? email.trim();

      if (context.mounted) {
        await _loadAndSetUser(context, uid, userEmail, name.trim());
      }

      _currentUserEmail = userEmail;
      _isAuthenticated = true;
      _setSuccess(
          'Welcome to Zenrova, ${Helpers.truncateText(name.trim(), 20)}!');
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
      await _authService.resetPassword(email.trim());
      _setSuccess('Reset link sent to ${email.trim()}. Check your inbox.');
      return true;
    } catch (e) {
      _setError('Could not send reset email. Try again later.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google sign-in (placeholder) ───────────────────────────────
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
  void continueAsGuest(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Uses createGuestUser — isAdmin is always false for guests
    userProvider.createGuestUser();
    _currentUserEmail = null;
    _isAuthenticated = true;
    _setSuccess('Continuing as guest');
  }

  // ── Sign out ───────────────────────────────────────────────────
  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUserEmail = null;
    clearMessages();
    await _authService.signOut();
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