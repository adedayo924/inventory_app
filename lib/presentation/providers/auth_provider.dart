import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/security/password_hasher.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get requiresPasswordChange => _currentUser?.mustChangePassword ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('jims_auth_user');
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auto-login error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userMap = await DatabaseHelper.instance.getUserByEmail(email);
      if (userMap == null) {
        _errorMessage = 'Invalid email address or user inactive.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final storedPassword = userMap['password'] as String? ?? '';
      final isValid = PasswordHasher.verify(password, storedPassword);

      if (!isValid) {
        _errorMessage = 'Incorrect password. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromMap(userMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jims_auth_user', jsonEncode(_currentUser!.toMap()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newHash = PasswordHasher.hash(newPassword);
      await DatabaseHelper.instance.updatePassword(_currentUser!.id, newHash);

      _currentUser = _currentUser!.copyWith(mustChangePassword: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jims_auth_user', jsonEncode(_currentUser!.toMap()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jims_auth_user');
    notifyListeners();
  }
}
