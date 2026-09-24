class CategoryModel {
  final int id;
  final String name;
  final String slug;

  CategoryModel({required this.id, required this.name, required this.slug});

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Category',
      slug: map['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'slug': slug};
}

class BrandModel {
  final int id;
  final String name;
  final String slug;

  BrandModel({required this.id, required this.name, required this.slug});

  factory BrandModel.fromMap(Map<String, dynamic> map) {
    return BrandModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Brand',
      slug: map['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'slug': slug};
}

class UnitModel {
  final int id;
  final String name;
  final String code;
  final String shortName;

  UnitModel({required this.id, required this.name, required this.code, required this.shortName});

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unit',
      code: map['code'] as String? ?? 'PCS',
      shortName: map['short_name'] as String? ?? 'pcs',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'code': code, 'short_name': shortName};
}

class CustomerModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;

  CustomerModel({required this.id, required this.name, this.email, this.phone, this.address});

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Customer',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'address': address};
}

class SupplierModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;

  SupplierModel({required this.id, required this.name, this.email, this.phone, this.address});

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Supplier',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'address': address};
}

class DistributorModel {
  final int id;
  final String name;
  final String? code;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
  final double totalEarned;
  final double totalPaid;

  DistributorModel({
    required this.id,
    required this.name,
    this.code,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
    this.totalEarned = 0.0,
    this.totalPaid = 0.0,
  });

  double get balance => totalEarned - totalPaid;

  factory DistributorModel.fromMap(Map<String, dynamic> map) {
    return DistributorModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Distributor',
      code: map['code'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      totalEarned: (map['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseModel {
  final int id;
  final int storeId;
  final int userId;
  final String description;
  final double amount;
  final String type;
  final String? note;
  final String createdAt;
  final String? loggedByName;

  ExpenseModel({
    required this.id,
    this.storeId = 1,
    required this.userId,
    required this.description,
    required this.amount,
    this.type = 'expense',
    this.note,
    required this.createdAt,
    this.loggedByName,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int? ?? 0,
      storeId: map['store_id'] as int? ?? 1,
      userId: map['user_id'] as int? ?? 1,
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      note: map['note'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      loggedByName: map['logged_by_name'] as String?,
    );
  }
}

class PurchaseModel {
  final int id;
  final int storeId;
  final int? supplierId;
  final int userId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String status;
  final String createdAt;
  final String? supplierName;
  final String? userName;

  PurchaseModel({
    required this.id,
    this.storeId = 1,
    this.supplierId,
    required this.userId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.status = 'received',
    required this.createdAt,
    this.supplierName,
    this.userName,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] as int? ?? 0,
      storeId: map['store_id'] as int? ?? 1,
      supplierId: map['supplier_id'] as int?,
      userId: map['user_id'] as int? ?? 1,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'received',
      createdAt: map['created_at'] as String? ?? '',
      supplierName: map['supplier_name'] as String?,
      userName: map['user_name'] as String?,
    );
  }
}

class DashboardMetrics {
  final double totalSales;
  final int totalOrders;
  final int totalProducts;
  final int lowStockCount;
  final int nearExpiryCount;
  final double inventoryValue;
  final double totalExpenses;
  final double totalCogs;
  final double grossProfit;
  final double netProfit;

  DashboardMetrics({
    this.totalSales = 0.0,
    this.totalOrders = 0,
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.nearExpiryCount = 0,
    this.inventoryValue = 0.0,
    this.totalExpenses = 0.0,
    this.totalCogs = 0.0,
    this.grossProfit = 0.0,
    this.netProfit = 0.0,
  });

  factory DashboardMetrics.fromMap(Map<String, dynamic> map) {
    return DashboardMetrics(
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalProducts: (map['total_products'] as num?)?.toInt() ?? 0,
      lowStockCount: (map['low_stock_count'] as num?)?.toInt() ?? 0,
      nearExpiryCount: (map['near_expiry_count'] as num?)?.toInt() ?? 0,
      inventoryValue: (map['inventory_value'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (map['total_expenses'] as num?)?.toDouble() ?? 0.0,
      totalCogs: (map['total_cogs'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (map['gross_profit'] as num?)?.toDouble() ?? 0.0,
      netProfit: (map['net_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
