import 'package:flutter/foundation.dart';
import '../../shared/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  
  UserModel? get user => _user;
  
  String get displayName => _user?.displayName ?? 'Guest';
  String get email => _user?.email ?? '';
  String? get avatarUrl => _user?.avatarUrl;
  bool get isAdmin => _user?.isAdmin ?? false;
  
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
  
  // For demo purposes, create a sample user
  void createSampleUser(String name, {bool isAdmin = false}) {
    _user = UserModel(
      id: 'demo-user-id',
      email: isAdmin ? 'admin@zenrova.com' : 'user@zenrova.com',
      displayName: name,
      avatarUrl: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isAdmin: isAdmin,
    );
    notifyListeners();
  }
  
  // Create admin user for testing
  void createAdminUser(String name) {
    createSampleUser(name, isAdmin: true);
  }
}
