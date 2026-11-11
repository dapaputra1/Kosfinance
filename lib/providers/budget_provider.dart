import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/bill_model.dart';

class BudgetProvider extends ChangeNotifier {
  double _monthlyBudget = 0.0;
  List<BillReminder> _bills = [];
  bool _isLoading = false;

  double get monthlyBudget => _monthlyBudget;
  List<BillReminder> get bills => _bills;
  bool get isLoading => _isLoading;

  int get pendingBillsCount => _bills.where((b) => !b.isPaid).length;

  double get pendingBillsTotal => _bills
      .where((b) => !b.isPaid)
      .fold(0.0, (sum, b) => sum + b.amount);

  Future<void> loadData(int? userId) async {
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyBudget = prefs.getDouble('budget_$userId') ?? 0.0;

      final billsString = prefs.getString('bills_$userId');
      if (billsString != null) {
        final List decoded = jsonDecode(billsString);
        _bills = decoded.map((e) => BillReminder.fromJson(e)).toList();
      } else {
        // Sample default bills for boarding students
        _bills = [
          BillReminder(
            id: '1',
            title: 'Sewa Kamar Kos',
            amount: 750000,
            dueDay: 5,
            isPaid: false,
            note: 'Transfer ke pemilik kos',
          ),
          BillReminder(
            id: '2',
            title: 'Listrik & Air',
            amount: 100000,
            dueDay: 15,
            isPaid: false,
            note: 'Iuran listrik dan air',
          ),
        ];
        await _saveBills(userId);
      }
    } catch (_) {
      // Ignore load error and fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setMonthlyBudget(int userId, double budget) async {
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_$userId', budget);
    notifyListeners();
  }

  Future<void> _saveBills(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _bills.map((b) => b.toJson()).toList();
    await prefs.setString('bills_$userId', jsonEncode(jsonList));
  }

  Future<void> addBill(int userId, BillReminder bill) async {
    _bills.add(bill);
    await _saveBills(userId);
    notifyListeners();
  }

  Future<void> updateBill(int userId, BillReminder bill) async {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
      await _saveBills(userId);
      notifyListeners();
    }
  }

  Future<void> deleteBill(int userId, String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _saveBills(userId);
    notifyListeners();
  }

  Future<void> toggleBillPaid(int userId, String id) async {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final current = _bills[index];
      _bills[index] = current.copyWith(isPaid: !current.isPaid);
      await _saveBills(userId);
      notifyListeners();
    }
  }
}
