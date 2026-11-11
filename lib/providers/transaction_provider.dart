import 'package:flutter/material.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/models/category_model.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/services/local_db_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = false;
  String? _error;
  int _currentUserId = 1;

  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  Map<String, dynamic> get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get recentTransactions {
    return _transactions.take(5).toList();
  }

  List<Category> getCategoriesByType(String type) {
    return _categories.where((category) => category.type == type).toList();
  }

  int _extractUserId(String token, [int? fallbackId]) {
    if (fallbackId != null && fallbackId > 0) {
      _currentUserId = fallbackId;
      return fallbackId;
    }
    if (token.contains('offline_token_')) {
      final parts = token.split('_');
      final last = parts.isNotEmpty ? parts.last : '';
      final parsed = int.tryParse(last);
      if (parsed != null) {
        _currentUserId = parsed;
        return parsed;
      }
    }
    return _currentUserId;
  }

  Future<void> fetchTransactions(String token, [int? userId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = _extractUserId(token, userId);

    if (!LocalDbService.isOfflineOnly) {
      try {
        _transactions = await ApiService.getTransactions(token);
        _isLoading = false;
        notifyListeners();
        return;
      } catch (_) {}
    }

    try {
      _transactions = await LocalDbService.getTransactions(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchCategories(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!LocalDbService.isOfflineOnly) {
      try {
        _categories = await ApiService.getCategories(token);
        _isLoading = false;
        notifyListeners();
        return;
      } catch (_) {}
    }

    try {
      _categories = await LocalDbService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Category?> addCategory(String name, String icon, String type, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!LocalDbService.isOfflineOnly) {
      try {
        final newCategory = await ApiService.addCategory(name, icon, type, token);
        _categories.add(newCategory);
        _isLoading = false;
        notifyListeners();
        return newCategory;
      } catch (_) {}
    }

    try {
      final newCategory = await LocalDbService.addCategory(name, icon, type);
      _categories.add(newCategory);
      _isLoading = false;
      notifyListeners();
      return newCategory;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchDashboardData(String token, [int? userId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = _extractUserId(token, userId);

    if (!LocalDbService.isOfflineOnly) {
      try {
        _dashboardData = await ApiService.getDashboardData(token);
        _isLoading = false;
        notifyListeners();
        return;
      } catch (_) {}
    }

    try {
      _dashboardData = await LocalDbService.getDashboardData(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Transaction transaction, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = _extractUserId(token, transaction.userId);

    if (!LocalDbService.isOfflineOnly) {
      try {
        final newTransaction = await ApiService.addTransaction(transaction, token);
        _transactions.insert(0, newTransaction);
        await fetchDashboardData(token, uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {}
    }

    try {
      final newTransaction = await LocalDbService.addTransaction(transaction);
      _transactions.insert(0, newTransaction);
      await fetchDashboardData(token, uid);
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

  Future<bool> updateTransaction(Transaction transaction, String token) async {
    if (transaction.id == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = _extractUserId(token, transaction.userId);

    if (!LocalDbService.isOfflineOnly) {
      try {
        final updated = await ApiService.updateTransaction(transaction.id!, transaction, token);
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = updated;
        }
        await fetchDashboardData(token, uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {}
    }

    try {
      final updated = await LocalDbService.updateTransaction(transaction.id!, transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updated;
      } else {
        _transactions.insert(0, updated);
      }
      await fetchDashboardData(token, uid);
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

  Future<bool> deleteTransaction(int id, String token, [int? userId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final uid = _extractUserId(token, userId);

    if (!LocalDbService.isOfflineOnly) {
      try {
        await ApiService.deleteTransaction(id, token);
        _transactions.removeWhere((transaction) => transaction.id == id);
        await fetchDashboardData(token, uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (_) {}
    }

    try {
      await LocalDbService.deleteTransaction(uid, id);
      _transactions.removeWhere((transaction) => transaction.id == id);
      await fetchDashboardData(token, uid);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
