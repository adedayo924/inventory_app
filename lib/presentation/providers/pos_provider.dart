import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  double customPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    double? customPrice,
  }) : customPrice = customPrice ?? product.sellPrice;

  double get subtotal => customPrice * quantity;
  double get taxAmount => (product.taxRate > 0) ? (subtotal * product.taxRate / 100) : 0.0;
  double get total => subtotal + taxAmount;
}

class PosProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];
  int? _selectedCustomerId = 1; // Default: Walk-in
  String _customerName = 'Walk-in Customer';
  int? _selectedDistributorId;
  String? _distributorName;
  double _discountAmount = 0.0;
  bool _isProcessing = false;

  List<CartItem> get cart => List.unmodifiable(_cart);
  int? get selectedCustomerId => _selectedCustomerId;
  String get customerName => _customerName;
  int? get selectedDistributorId => _selectedDistributorId;
  String? get distributorName => _distributorName;
  double get discountAmount => _discountAmount;
  bool get isProcessing => _isProcessing;

  int get totalItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get taxTotal => _cart.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => (subtotal + taxTotal - _discountAmount).clamp(0.0, double.infinity);

  void addToCart(ProductModel product, {int quantity = 1}) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cart[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discountAmount = 0.0;
    _selectedCustomerId = 1;
    _customerName = 'Walk-in Customer';
    _selectedDistributorId = null;
    _distributorName = null;
    notifyListeners();
  }

  void setCustomer(int? id, String name) {
    _selectedCustomerId = id;
    _customerName = name;
    notifyListeners();
  }

  void setDistributor(int? id, String? name) {
    _selectedDistributorId = id;
    _distributorName = name;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discountAmount = amount.clamp(0.0, subtotal + taxTotal);
    notifyListeners();
  }

  Future<SaleModel?> checkout({
    required int userId,
    required String paymentMethod,
    required double paidAmount,
    String? cashierName,
  }) async {
    if (_cart.isEmpty) return null;
    _isProcessing = true;
    notifyListeners();

    try {
      final invoice = Formatters.generateInvoiceNumber();
      final total = grandTotal;
      final change = (paidAmount - total).clamp(0.0, double.infinity);
      final now = DateTime.now().toIso8601String();

      final saleData = {
        'store_id': 1,
        'user_id': userId,
        'customer_id': _selectedCustomerId,
        'distributor_id': _selectedDistributorId,
        'invoice_number': invoice,
        'subtotal': subtotal,
        'tax_amount': taxTotal,
        'total': total,
        'paid': paidAmount,
        'change': change,
        'status': 'completed',
        'payment_method': paymentMethod.toLowerCase(),
        'sync_status': 'synced',
      };

      final saleItemsData = _cart.map((item) => {
        'product_id': item.product.id,
        'product_name': item.product.name,
        'product_sku': item.product.sku,
        'quantity': item.quantity,
        'unit_price': item.customPrice,
        'subtotal': item.subtotal,
      }).toList();

      final saleId = await DatabaseHelper.instance.createSale(
        saleData: saleData,
        items: saleItemsData,
        distributorId: _selectedDistributorId,
      );

      final completedSale = SaleModel(
        id: saleId,
        userId: userId,
        customerId: _selectedCustomerId,
        distributorId: _selectedDistributorId,
        invoiceNumber: invoice,
        subtotal: subtotal,
        taxAmount: taxTotal,
        total: total,
        paid: paidAmount,
        change: change,
        status: 'completed',
        paymentMethod: paymentMethod,
        createdAt: now,
        customerName: _customerName,
        cashierName: cashierName,
        distributorName: _distributorName,
        items: _cart.map((item) => SaleItemModel(
          productId: item.product.id,
          productName: item.product.name,
          productSku: item.product.sku,
          quantity: item.quantity,
          unitPrice: item.customPrice,
          subtotal: item.subtotal,
        )).toList(),
      );

      clearCart();
      _isProcessing = false;
      notifyListeners();
      return completedSale;
    } catch (e) {
      debugPrint('Checkout error: $e');
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
}
