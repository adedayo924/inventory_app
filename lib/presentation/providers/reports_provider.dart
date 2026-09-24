import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/auxiliary_models.dart';

class ReportsProvider extends ChangeNotifier {
  DashboardMetrics _metrics = DashboardMetrics();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportsProvider() {
    loadDashboardMetrics();
  }

  Future<void> loadDashboardMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final map = await DatabaseHelper.instance.getDashboardMetrics();
      _metrics = DashboardMetrics.fromMap(map);
    } catch (e) {
      _errorMessage = 'Failed to load metrics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
