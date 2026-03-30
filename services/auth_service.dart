import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zenrova/shared/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
    });
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        return _userModelFromFirebase(result.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<UserModel?> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        return _userModelFromFirebase(result.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  UserModel _userModelFromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime ?? DateTime.now(),
      isEmailVerified: user.emailVerified,
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}