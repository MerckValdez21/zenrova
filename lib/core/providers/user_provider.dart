import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isDarkMode = false;

  UserProvider() {
    // Ensure we start in light mode
    _isDarkMode = false;
  }

  UserModel? get user => _user;

  String get displayName => _user?.displayName ?? 'Guest';
  String get email => _user?.email ?? '';
  String? get avatarUrl => _user?.avatarUrl;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void updateUser({
    String? displayName,
    String? avatarUrl,
    bool? isAdmin,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
        isAdmin: isAdmin,
      );
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Used only by AdminLoginScreen — sets isAdmin = true
  void createAdminUser(String name) {
    _user = UserModel(
      id: 'admin-demo-id',
      email: 'admin@zenrova.com',
      displayName: name,
      avatarUrl: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isAdmin: true,
    );
    notifyListeners();
  }

  // For guest access — isAdmin is always false
  void createGuestUser() {
    _user = UserModel(
      id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      displayName: 'Guest',
      avatarUrl: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: false,
      isAdmin: false,
    );
    notifyListeners();
  }
}