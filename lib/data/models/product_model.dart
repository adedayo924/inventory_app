class ProductModel {
  final int id;
  final int? categoryId;
  final int? unitId;
  final int? brandId;
  final String name;
  final String slug;
  final String sku;
  final String? barcode;
  final double costPrice;
  final double sellPrice;
  final double taxRate;
  final double commissionRate;
  final int alertQuantity;
  final String? expiryDate;
  final String? description;
  final bool isActive;
  final int quantity;
  final String? categoryName;
  final String? brandName;
  final String? unitName;

  ProductModel({
    required this.id,
    this.categoryId,
    this.unitId,
    this.brandId,
    required this.name,
    required this.slug,
    required this.sku,
    this.barcode,
    required this.costPrice,
    required this.sellPrice,
    this.taxRate = 0.0,
    this.commissionRate = 0.0,
    this.alertQuantity = 10,
    this.expiryDate,
    this.description,
    this.isActive = true,
    this.quantity = 0,
    this.categoryName,
    this.brandName,
    this.unitName,
  });

  bool get isLowStock => quantity <= alertQuantity;

  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    final exp = DateTime.tryParse(expiryDate!);
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  bool get isNearExpiry {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    final exp = DateTime.tryParse(expiryDate!);
    if (exp == null) return false;
    final daysLeft = exp.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 30;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int? ?? 0,
      categoryId: map['category_id'] as int?,
      unitId: map['unit_id'] as int?,
      brandId: map['brand_id'] as int?,
      name: map['name'] as String? ?? 'Product',
      slug: map['slug'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      barcode: map['barcode'] as String?,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (map['commission_rate'] as num?)?.toDouble() ?? 0.0,
      alertQuantity: map['alert_quantity'] as int? ?? 10,
      expiryDate: map['expiry_date'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      categoryName: map['category_name'] as String?,
      brandName: map['brand_name'] as String?,
      unitName: map['unit_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'unit_id': unitId,
      'brand_id': brandId,
      'name': name,
      'slug': slug,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'tax_rate': taxRate,
      'commission_rate': commissionRate,
      'alert_quantity': alertQuantity,
      'expiry_date': expiryDate,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    int? unitId,
    int? brandId,
    String? name,
    String? slug,
    String? sku,
    String? barcode,
    double? costPrice,
    double? sellPrice,
    double? taxRate,
    double? commissionRate,
    int? alertQuantity,
    String? expiryDate,
    String? description,
    bool? isActive,
    int? quantity,
    String? categoryName,
    String? brandName,
    String? unitName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      taxRate: taxRate ?? this.taxRate,
      commissionRate: commissionRate ?? this.commissionRate,
      alertQuantity: alertQuantity ?? this.alertQuantity,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      quantity: quantity ?? this.quantity,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      unitName: unitName ?? this.unitName,
    );
  }
}
