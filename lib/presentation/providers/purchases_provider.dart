import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auxiliary_models.dart';

class PurchasesProvider extends ChangeNotifier {
  List<PurchaseModel> _purchases = [];
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PurchaseModel> get purchases => _purchases;
  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PurchasesProvider() {
    loadPurchases();
    loadSuppliers();
  }

  Future<void> loadPurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await DatabaseHelper.instance.getPurchases();
      _purchases = rows.map((r) => PurchaseModel.fromMap(r)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load purchases: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuppliers() async {
    try {
      final rows = await DatabaseHelper.instance.getSuppliers();
      _suppliers = rows.map((r) => SupplierModel.fromMap(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load suppliers error: $e');
    }
  }

  Future<bool> createPurchaseOrder({
    required int? supplierId,
    required int userId,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final invoice = Formatters.generatePurchaseInvoice();
      double subtotal = 0.0;
      for (var item in items) {
        subtotal += (item['subtotal'] as num).toDouble();
      }

      final purchaseData = {
        'store_id': 1,
        'supplier_id': supplierId,
        'user_id': userId,
        'invoice_number': invoice,
        'subtotal': subtotal,
        'tax_amount': 0.0,
        'total': subtotal,
        'status': 'received',
      };

      await DatabaseHelper.instance.createPurchase(
        purchaseData: purchaseData,
        items: items,
      );

      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Create purchase failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
