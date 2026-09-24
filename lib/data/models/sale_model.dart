class SaleItemModel {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String productSku;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name'] as String? ?? 'Item',
      productSku: map['product_sku'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class SaleModel {
  final int id;
  final int storeId;
  final int userId;
  final int? customerId;
  final int? distributorId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double total;
  final double paid;
  final double change;
  final String status; // 'completed', 'cancelled'
  final String paymentMethod; // 'cash', 'card', 'transfer'
  final String syncStatus;
  final String createdAt;
  final String? customerName;
  final String? cashierName;
  final String? distributorName;
  final List<SaleItemModel> items;

  SaleModel({
    required this.id,
    this.storeId = 1,
    required this.userId,
    this.customerId,
    this.distributorId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.taxAmount,
    this.discount = 0.0,
    required this.total,
    required this.paid,
    required this.change,
    this.status = 'completed',
    this.paymentMethod = 'cash',
    this.syncStatus = 'synced',
    required this.createdAt,
    this.customerName,
    this.cashierName,
    this.distributorName,
    this.items = const [],
  });

  factory SaleModel.fromMap(Map<String, dynamic> map, {List<SaleItemModel> items = const []}) {
    return SaleModel(
      id: map['id'] as int? ?? 0,
      storeId: map['store_id'] as int? ?? 1,
      userId: map['user_id'] as int? ?? 1,
      customerId: map['customer_id'] as int?,
      distributorId: map['distributor_id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paid: (map['paid'] as num?)?.toDouble() ?? 0.0,
      change: (map['change'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'completed',
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      syncStatus: map['sync_status'] as String? ?? 'synced',
      createdAt: map['created_at'] as String? ?? '',
      customerName: map['customer_name'] as String?,
      cashierName: map['cashier_name'] as String?,
      distributorName: map['distributor_name'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'user_id': userId,
      'customer_id': customerId,
      'distributor_id': distributorId,
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount': discount,
      'total': total,
      'paid': paid,
      'change': change,
      'status': status,
      'payment_method': paymentMethod,
      'sync_status': syncStatus,
      'created_at': createdAt,
    };
  }
}
