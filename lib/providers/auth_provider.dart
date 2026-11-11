import 'dart:convert'; // <-- Tambahkan ini untuk akses json.encode & json.decode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/user_model.dart';
import 'package:kos_finance_app/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

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

  String _formatErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('SocketException') ||
        str.contains('Connection failed') ||
        str.contains('ClientException')) {
      return 'Tidak dapat terhubung ke server di (${ApiService.baseUrl}).\n'
          'Jika Anda menggunakan HP fisik, pastikan HP & laptop di Wi-Fi yang sama dan ganti alamat server ke IP laptop Anda.';
    }
    if (str.contains('Email already in use')) {
      return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
    }
    if (str.contains('Invalid credentials') ||
        str.contains('401') ||
        str.toLowerCase().contains('invalid')) {
      return 'Email atau kata sandi salah. Silakan periksa kembali.';
    }
    return str.replaceAll('Exception: ', '');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.login(email, password);
      _user = user;
      await _saveUserToPrefs(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.register(name, email, password);
      _user = user;
      await _saveUserToPrefs(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String? password) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

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
