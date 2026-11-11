import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/user_model.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        _user = User.fromJson(Map<String, dynamic>.from(
          json.decode(userData)
        ));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'token': user.token,
    }));
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1. Try online first if not in offline-only mode
    if (!LocalDbService.isOfflineOnly) {
      try {
        final user = await ApiService.login(email, password);
        _user = user;
        _isOfflineMode = false;
        await _saveUserToPrefs(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // If server connection fails, seamlessly fallback to offline local database
      }
    }

    // 2. Offline / Local fallback: ALWAYS succeeds for the user!
    try {
      final user = await LocalDbService.login(email, password);
      _user = user;
      _isOfflineMode = true;
      await _saveUserToPrefs(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal masuk: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1. Try online first if not forced offline
    if (!LocalDbService.isOfflineOnly) {
      try {
        final user = await ApiService.register(name, email, password);
        _user = user;
        _isOfflineMode = false;
        await _saveUserToPrefs(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // If server connection fails, seamlessly save locally
      }
    }

    // 2. Offline / Local fallback: ALWAYS succeeds!
    try {
      final user = await LocalDbService.register(name, email, password);
      _user = user;
      _isOfflineMode = true;
      await _saveUserToPrefs(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal pendaftaran: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginGuest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await LocalDbService.loginAsGuest();
      _user = user;
      _isOfflineMode = true;
      await _saveUserToPrefs(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String? password) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Try online
    if (!_isOfflineMode) {
      try {
        final updatedUser = await ApiService.updateProfile(
          name: name,
          password: password,
          token: _user!.token,
        );
        _user = updatedUser;
        await _saveUserToPrefs(updatedUser);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {}
    }

    // Always update local database
    try {
      final updatedUser = await LocalDbService.updateProfile(
        _user!.id,
        name,
        _user!.email,
        newPassword: password,
      );
      _user = updatedUser;
      await _saveUserToPrefs(updatedUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
