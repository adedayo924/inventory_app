import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/auxiliary_models.dart';

class ExpensesProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  ExpensesProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await DatabaseHelper.instance.getExpenses();
      _expenses = rows.map((r) => ExpenseModel.fromMap(r)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required int userId,
    required String description,
    required double amount,
    String type = 'expense',
    String? note,
  }) async {
    try {
      await DatabaseHelper.instance.insertExpense({
        'store_id': 1,
        'user_id': userId,
        'description': description,
        'amount': amount,
        'type': type,
        'note': note,
      });
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }
}
