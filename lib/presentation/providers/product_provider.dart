import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/csv_helper.dart';
import '../../data/models/auxiliary_models.dart';
import '../../data/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<UnitModel> _units = [];

  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  List<UnitModel> get units => _units;

  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalLowStockCount => _products.where((p) => p.isLowStock).length;
  int get totalExpiredCount => _products.where((p) => p.isExpired).length;
  int get totalNearExpiryCount => _products.where((p) => p.isNearExpiry).length;

  ProductProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;

      final pRows = await db.getProductsWithInventory(
        query: _searchQuery,
        categoryId: _selectedCategoryId,
      );
      _products = pRows.map((r) => ProductModel.fromMap(r)).toList();

      final cRows = await db.getCategories();
      _categories = cRows.map((r) => CategoryModel.fromMap(r)).toList();

      final bRows = await db.getBrands();
      _brands = bRows.map((r) => BrandModel.fromMap(r)).toList();

      final uRows = await db.getUnits();
      _units = uRows.map((r) => UnitModel.fromMap(r)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadData();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadData();
  }

  ProductModel? findByBarcodeOrSku(String code) {
    final clean = code.trim().toLowerCase();
    for (final p in _products) {
      if ((p.barcode != null && p.barcode!.toLowerCase() == clean) || p.sku.toLowerCase() == clean) {
        return p;
      }
    }
    return null;
  }

  Future<bool> addProduct(Map<String, dynamic> productData, int initialQuantity) async {
    try {
      await DatabaseHelper.instance.insertProduct(productData, initialQuantity);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Add product failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData, int quantity) async {
    try {
      await DatabaseHelper.instance.updateProduct(id, productData, quantity);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Update product failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Delete product failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> importFromCsv() async {
    final parsed = await CsvHelper.pickAndParseCsv();
    if (parsed == null) return false;

    int successCount = 0;
    for (final p in parsed.products) {
      final qty = p['quantity'] as int? ?? 0;
      final added = await addProduct(p, qty);
      if (added) successCount++;
    }

    await loadData();
    return successCount > 0;
  }
}
