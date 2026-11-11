import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/savings_goal_model.dart';

class SavingsProvider with ChangeNotifier {
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;

  double get totalSaved =>
      _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  double get totalTarget =>
      _goals.fold(0.0, (sum, g) => sum + g.targetAmount);

  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  int get achievedGoalsCount =>
      _goals.where((g) => g.isAchieved).length;

  Future<void> loadGoals(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'kos_savings_goals_$userId';
      final jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        _goals = list.map((item) => SavingsGoal.fromJson(item)).toList();
      } else {
        // Defaults for anak kos if empty
        _goals = [
          SavingsGoal(
            id: '1',
            title: 'Dana Darurat Kos',
            targetAmount: 1000000,
            currentAmount: 350000,
            note: 'Cadangan darurat kalau sakit atau ada kebutuhan mendesak',
            icon: 'shield',
          ),
          SavingsGoal(
            id: '2',
            title: 'Pulang Kampung',
            targetAmount: 500000,
            currentAmount: 200000,
            note: 'Ongkos tiket kereta/bus liburan semester',
            icon: 'flight',
          ),
        ];
        await _saveToGoals(userId);
      }
    } catch (e) {
      debugPrint('Error loading savings goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(int userId, SavingsGoal goal) async {
    _goals.insert(0, goal);
    notifyListeners();
    await _saveToGoals(userId);
  }

  Future<void> updateGoal(int userId, SavingsGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      notifyListeners();
      await _saveToGoals(userId);
    }
  }

  Future<void> deleteGoal(int userId, String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    await _saveToGoals(userId);
  }

  Future<void> deposit(int userId, String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1 && amount > 0) {
      final current = _goals[index];
      _goals[index] = current.copyWith(
        currentAmount: current.currentAmount + amount,
      );
      notifyListeners();
      await _saveToGoals(userId);
    }
  }

  Future<void> withdraw(int userId, String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1 && amount > 0) {
      final current = _goals[index];
      final newAmount = (current.currentAmount - amount).clamp(0.0, double.infinity);
      _goals[index] = current.copyWith(
        currentAmount: newAmount,
      );
      notifyListeners();
      await _saveToGoals(userId);
    }
  }

  Future<void> _saveToGoals(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'kos_savings_goals_$userId';
      final jsonString = json.encode(_goals.map((g) => g.toJson()).toList());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving savings goals: $e');
    }
  }
}
