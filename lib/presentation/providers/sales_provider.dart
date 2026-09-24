import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/sale_model.dart';

class SalesProvider extends ChangeNotifier {
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SalesProvider() {
    loadSales();
  }

  Future<void> loadSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await DatabaseHelper.instance.getSales(limit: 100);
      final List<SaleModel> loaded = [];

      for (var row in rows) {
        final saleId = row['id'] as int;
        final itemRows = await DatabaseHelper.instance.getSaleItems(saleId);
        final items = itemRows.map((i) => SaleItemModel.fromMap(i)).toList();
        loaded.add(SaleModel.fromMap(row, items: items));
      }

      _sales = loaded;
    } catch (e) {
      _errorMessage = 'Failed to load sales: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
