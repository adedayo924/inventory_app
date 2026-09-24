import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/sale_model.dart';

class SalesProvider extends ChangeNotifier {
  List<SaleModel> _sales = [];
  List<SaleModel> _filteredSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _paymentFilter = 'All'; // All / cash / card / mobile

  List<SaleModel> get sales => _filteredSales;
  List<SaleModel> get allSales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  String get paymentFilter => _paymentFilter;

  double get filteredTotal =>
      _filteredSales.fold(0.0, (sum, s) => sum + s.total);
  int get filteredCount => _filteredSales.length;

  SalesProvider() {
    loadSales();
  }

  Future<void> loadSales({String? from, String? to}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? fromStr = from ??
          (_fromDate != null ? _formatDate(_fromDate!) : null);
      final String? toStr =
          to ?? (_toDate != null ? _formatDate(_toDate!) : null);

      List<Map<String, dynamic>> rows;
      if (fromStr != null || toStr != null) {
        rows = await DatabaseHelper.instance.getSalesByDateRange(
          from: fromStr,
          to: toStr,
          limit: 300,
        );
      } else {
        rows = await DatabaseHelper.instance.getSales(limit: 300);
      }

      final List<SaleModel> loaded = [];
      for (var row in rows) {
        final saleId = row['id'] as int;
        final itemRows = await DatabaseHelper.instance.getSaleItems(saleId);
        final items = itemRows.map((i) => SaleItemModel.fromMap(i)).toList();
        loaded.add(SaleModel.fromMap(row, items: items));
      }
      _sales = loaded;
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load sales: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setPaymentFilter(String method) {
    _paymentFilter = method;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    loadSales();
  }

  void clearFilters() {
    _searchQuery = '';
    _fromDate = null;
    _toDate = null;
    _paymentFilter = 'All';
    loadSales();
  }

  void _applyFilters() {
    _filteredSales = _sales.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s.invoiceNumber.toLowerCase().contains(q) ||
          (s.customerName ?? '').toLowerCase().contains(q) ||
          (s.cashierName ?? '').toLowerCase().contains(q);

      final matchesPayment = _paymentFilter == 'All' ||
          s.paymentMethod.toLowerCase() == _paymentFilter.toLowerCase();

      return matchesSearch && matchesPayment;
    }).toList();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
