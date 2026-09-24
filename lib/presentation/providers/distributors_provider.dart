import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/auxiliary_models.dart';

class DistributorsProvider extends ChangeNotifier {
  List<DistributorModel> _distributors = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DistributorModel> get distributors => _distributors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DistributorsProvider() {
    loadDistributors();
  }

  Future<void> loadDistributors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await DatabaseHelper.instance.getDistributors();
      _distributors = rows.map((r) => DistributorModel.fromMap(r)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load distributors: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDistributor(Map<String, dynamic> data) async {
    try {
      final now = DateTime.now().toIso8601String();
      await DatabaseHelper.instance.insertDistributor({
        ...data,
        'created_at': now,
        'updated_at': now,
      });
      await loadDistributors();
      return true;
    } catch (e) {
      _errorMessage = 'Add distributor failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> payCommission({
    required int distributorId,
    required double amount,
    required String reference,
    required String note,
    required int userId,
  }) async {
    try {
      await DatabaseHelper.instance.recordCommissionPayment(
        distributorId,
        amount,
        reference,
        note,
        userId,
      );
      await loadDistributors();
      return true;
    } catch (e) {
      _errorMessage = 'Payout failed: $e';
      notifyListeners();
      return false;
    }
  }
}
