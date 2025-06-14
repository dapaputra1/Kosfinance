import 'package:flutter/material.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/models/category_model.dart';
import 'package:kos_finance_app/services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = false;
  String? _error;

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

  Future<void> fetchTransactions(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await ApiService.getTransactions(token);
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

    try {
      _categories = await ApiService.getCategories(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await ApiService.getDashboardData(token);
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

    try {
      final newTransaction = await ApiService.addTransaction(transaction, token);
      _transactions.insert(0, newTransaction);
      await fetchDashboardData(token); // Refresh dashboard data
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

  Future<bool> deleteTransaction(int id, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.deleteTransaction(id, token);
      _transactions.removeWhere((transaction) => transaction.id == id);
      await fetchDashboardData(token); // Refresh dashboard data
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
