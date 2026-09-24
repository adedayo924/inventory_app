import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqflite.dart';

import '../security/password_hasher.dart';
import 'database_paths.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const int _dbVersion = 2;
  static const String dbName = 'jeilo_jims.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      try {
        return await databaseFactory.openDatabase(
          fileName,
          options: OpenDatabaseOptions(
            version: _dbVersion,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ),
        );
      } catch (e) {
        debugPrint('Web database init failed, falling back to in-memory: $e');
        return await databaseFactory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: _dbVersion,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ),
        );
      }
    }

    final path = await resolveDatabasePath(fileName);
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Stores
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        address TEXT,
        phone TEXT,
        email TEXT,
        currency TEXT NOT NULL DEFAULT 'NGN',
        currency_symbol TEXT NOT NULL DEFAULT '₦',
        is_active INTEGER NOT NULL DEFAULT 1,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier',
        is_active INTEGER NOT NULL DEFAULT 1,
        must_change_password INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Brands
    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 5. Units
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        short_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 6. Suppliers
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 7. Customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 8. Distributors
    await db.execute('''
      CREATE TABLE distributors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT UNIQUE,
        phone TEXT,
        email TEXT,
        address TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 9. Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        unit_id INTEGER,
        brand_id INTEGER,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT,
        cost_price REAL NOT NULL DEFAULT 0,
        sell_price REAL NOT NULL DEFAULT 0,
        tax_rate REAL NOT NULL DEFAULT 0,
        commission_rate REAL NOT NULL DEFAULT 0,
        alert_quantity INTEGER NOT NULL DEFAULT 10,
        expiry_date TEXT,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 10. Product Store Inventory
    await db.execute('''
      CREATE TABLE product_store (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        alert_quantity INTEGER NOT NULL DEFAULT 10,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(product_id, store_id)
      )
    ''');

    // 11. Sales
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        customer_id INTEGER,
        distributor_id INTEGER,
        invoice_number TEXT NOT NULL UNIQUE,
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid REAL NOT NULL DEFAULT 0,
        change REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        payment_method TEXT NOT NULL DEFAULT 'cash',
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 12. Sale Items
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        product_sku TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 13. Purchases
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        supplier_id INTEGER,
        user_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL UNIQUE,
        subtotal REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'received',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 14. Purchase Items
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 15. Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'expense',
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 16. Commissions
    await db.execute('''
      CREATE TABLE commissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        sale_item_id INTEGER NOT NULL,
        distributor_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        product_sku TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        sell_price REAL NOT NULL DEFAULT 0,
        profit_per_unit REAL NOT NULL DEFAULT 0,
        commission_rate REAL NOT NULL DEFAULT 0,
        commission_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'earned',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 17. Commission Payments
    await db.execute('''
      CREATE TABLE commission_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        distributor_id INTEGER NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        reference TEXT,
        note TEXT,
        paid_by INTEGER,
        paid_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 18. Settings
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Seed Neutral Retail Starter Data for JIMS
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Default Supermarket Store
    await db.insert('stores', {
      'id': 1,
      'name': 'Jeilo Supermarket & Retail Store',
      'code': 'JIMS-HQ',
      'address': 'Plot 10 Commercial Hub, Central City',
      'phone': '+234 800 123 4567',
      'email': 'store@jeilo.com',
      'currency': 'NGN',
      'currency_symbol': '₦',
      'is_active': 1,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Seed Users with Salted PBKDF2 Hashed Passwords
    final defaultPasswordHash = PasswordHasher.hash('password');

    await db.insert('users', {
      'id': 1,
      'store_id': 1,
      'name': 'System Administrator',
      'email': 'admin@jeilo.com',
      'password': defaultPasswordHash,
      'role': 'admin',
      'is_active': 1,
      'must_change_password': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('users', {
      'id': 2,
      'store_id': 1,
      'name': 'Store Manager',
      'email': 'manager@jeilo.com',
      'password': defaultPasswordHash,
      'role': 'manager',
      'is_active': 1,
      'must_change_password': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('users', {
      'id': 3,
      'store_id': 1,
      'name': 'POS Cashier',
      'email': 'cashier@jeilo.com',
      'password': defaultPasswordHash,
      'role': 'cashier',
      'is_active': 1,
      'must_change_password': 0,
      'created_at': now,
      'updated_at': now,
    });

    // Settings
    final settingsMap = {
      'store_name': 'Jeilo Supermarket & Retail Store',
      'store_phone': '+234 800 123 4567',
      'store_email': 'info@jeilo.com',
      'currency_symbol': '₦',
      'tax_rate': '7.5',
      'expiry_alert_days': '30',
      'receipt_footer': 'Thank you for shopping with Jeilo! Quality guaranteed.',
    };

    for (var entry in settingsMap.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Categories
    final categories = [
      {'id': 1, 'name': 'Groceries & Foodstuffs', 'slug': 'groceries-foodstuffs'},
      {'id': 2, 'name': 'Beverages & Drinks', 'slug': 'beverages-drinks'},
      {'id': 3, 'name': 'Bakery & Confectionery', 'slug': 'bakery-confectionery'},
      {'id': 4, 'name': 'Dairy & Refrigerated', 'slug': 'dairy-refrigerated'},
      {'id': 5, 'name': 'Household & Cleaning', 'slug': 'household-cleaning'},
      {'id': 6, 'name': 'Personal Care & Hygiene', 'slug': 'personal-care-hygiene'},
    ];
    for (var c in categories) {
      await db.insert('categories', {...c, 'created_at': now, 'updated_at': now});
    }

    // Brands
    final brands = [
      {'id': 1, 'name': 'Jeilo Select', 'slug': 'jeilo-select'},
      {'id': 2, 'name': 'Golden Harvest', 'slug': 'golden-harvest'},
      {'id': 3, 'name': 'Nestle', 'slug': 'nestle'},
      {'id': 4, 'name': 'Peak Dairy', 'slug': 'peak-dairy'},
      {'id': 5, 'name': 'Coca-Cola', 'slug': 'coca-cola'},
      {'id': 6, 'name': 'Unilever', 'slug': 'unilever'},
      {'id': 7, 'name': 'Dettol', 'slug': 'dettol'},
    ];
    for (var b in brands) {
      await db.insert('brands', {...b, 'created_at': now, 'updated_at': now});
    }

    // Units
    final units = [
      {'id': 1, 'name': 'Pieces', 'code': 'PCS', 'short_name': 'pcs'},
      {'id': 2, 'name': 'Kilograms', 'code': 'KG', 'short_name': 'kg'},
      {'id': 3, 'name': 'Litres', 'code': 'LTR', 'short_name': 'L'},
      {'id': 4, 'name': 'Packs', 'code': 'PK', 'short_name': 'pk'},
      {'id': 5, 'name': 'Cartons', 'code': 'CTN', 'short_name': 'ctn'},
    ];
    for (var u in units) {
      await db.insert('units', {...u, 'created_at': now, 'updated_at': now});
    }

    // Customers
    await db.insert('customers', {
      'id': 1,
      'name': 'Walk-in Customer',
      'email': null,
      'phone': '0000000000',
      'address': 'Over the Counter',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('customers', {
      'id': 2,
      'name': 'Sarah Adebayo',
      'email': 'sarah@example.com',
      'phone': '08023456789',
      'address': '15 Victoria Avenue, Lagos',
      'created_at': now,
      'updated_at': now,
    });

    // Suppliers
    await db.insert('suppliers', {
      'id': 1,
      'name': 'Apex FMCG Mega Wholesalers',
      'email': 'orders@apexfmcg.com',
      'phone': '08011223344',
      'address': 'Industrial Avenue, Ikeja',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('suppliers', {
      'id': 2,
      'name': 'Prime Foods Distribution Ltd',
      'email': 'supply@primefoods.com',
      'phone': '08099887766',
      'address': 'Wholesale Park, Apapa',
      'created_at': now,
      'updated_at': now,
    });

    // Distributors
    await db.insert('distributors', {
      'id': 1,
      'name': 'Jeilo Metro Logistics',
      'code': 'DIST-001',
      'phone': '08033445566',
      'email': 'metro@jeilo-distro.com',
      'address': 'Lagos Mainland Depot',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Neutral Supermarket Retail Products
    final products = [
      {
        'id': 1,
        'category_id': 1, // Groceries
        'unit_id': 1,
        'brand_id': 2, // Golden Harvest
        'name': 'Golden Harvest Royal Basmati Rice (5kg)',
        'slug': 'golden-harvest-basmati-rice-5kg',
        'sku': 'GH-RICE-5KG',
        'barcode': '789123456001',
        'cost_price': 11000.0,
        'sell_price': 13500.0,
        'tax_rate': 0.0,
        'commission_rate': 2.5,
        'alert_quantity': 15,
        'expiry_date': '2027-12-31',
        'description': 'Premium long-grain aged aromatic Basmati rice 5kg pack.',
        'quantity': 45,
      },
      {
        'id': 2,
        'category_id': 2, // Beverages
        'unit_id': 1,
        'brand_id': 5, // Coca-Cola
        'name': 'Coca-Cola Zero Sugar (50cl Bottle - Pack of 12)',
        'slug': 'coca-cola-zero-sugar-50cl-pack',
        'sku': 'CC-ZERO-50CL-PK',
        'barcode': '789123456002',
        'cost_price': 3200.0,
        'sell_price': 4200.0,
        'tax_rate': 7.5,
        'commission_rate': 3.0,
        'alert_quantity': 10,
        'expiry_date': '2027-06-30',
        'description': 'Refreshing zero sugar sparkling beverage in convenient pack.',
        'quantity': 30,
      },
      {
        'id': 3,
        'category_id': 4, // Dairy
        'unit_id': 1,
        'brand_id': 4, // Peak Dairy
        'name': 'Peak Instant Full Cream Milk Powder (400g Tin)',
        'slug': 'peak-instant-milk-powder-400g',
        'sku': 'PEAK-MILK-400G',
        'barcode': '789123456003',
        'cost_price': 2800.0,
        'sell_price': 3600.0,
        'tax_rate': 0.0,
        'commission_rate': 2.0,
        'alert_quantity': 20,
        'expiry_date': '2027-08-15',
        'description': 'Rich and creamy instant milk enriched with 28 vitamins and minerals.',
        'quantity': 8, // Low stock on purpose for testing alerts
      },
      {
        'id': 4,
        'category_id': 3, // Bakery
        'unit_id': 1,
        'brand_id': 1, // Jeilo Select
        'name': 'Jeilo Fresh Sliced Butter Bread (800g Jumbo)',
        'slug': 'jeilo-fresh-sliced-butter-bread-800g',
        'sku': 'JF-BREAD-800G',
        'barcode': '789123456004',
        'cost_price': 1200.0,
        'sell_price': 1600.0,
        'tax_rate': 0.0,
        'commission_rate': 0.0,
        'alert_quantity': 10,
        'expiry_date': '2026-10-05', // Near expiry for alert demonstration
        'description': 'Freshly baked soft butter bread made with pure ingredients.',
        'quantity': 25,
      },
      {
        'id': 5,
        'category_id': 5, // Household & Cleaning
        'unit_id': 1,
        'brand_id': 7, // Dettol
        'name': 'Dettol Antiseptic Liquid (500ml)',
        'slug': 'dettol-antiseptic-liquid-500ml',
        'sku': 'DETTOL-ANT-500ML',
        'barcode': '789123456005',
        'cost_price': 2200.0,
        'sell_price': 2950.0,
        'tax_rate': 7.5,
        'commission_rate': 4.0,
        'alert_quantity': 12,
        'expiry_date': '2028-01-01',
        'description': 'Proven effective disinfectant for first aid and surface sanitizing.',
        'quantity': 50,
      },
      {
        'id': 6,
        'category_id': 6, // Personal Care
        'unit_id': 1,
        'brand_id': 6, // Unilever
        'name': 'Dove Deep Moisture Body Wash (450ml)',
        'slug': 'dove-deep-moisture-body-wash-450ml',
        'sku': 'DOVE-BW-450ML',
        'barcode': '789123456006',
        'cost_price': 3800.0,
        'sell_price': 5200.0,
        'tax_rate': 7.5,
        'commission_rate': 3.5,
        'alert_quantity': 8,
        'expiry_date': '2028-05-20',
        'description': 'Gentle hydrating body wash for soft, smooth skin.',
        'quantity': 18,
      },
      {
        'id': 7,
        'category_id': 1, // Groceries
        'unit_id': 1,
        'brand_id': 1, // Jeilo Select
        'name': 'Jeilo Pure Sunflower Cooking Oil (2 Litres)',
        'slug': 'jeilo-pure-sunflower-oil-2l',
        'sku': 'JF-OIL-2L',
        'barcode': '789123456007',
        'cost_price': 5500.0,
        'sell_price': 7200.0,
        'tax_rate': 0.0,
        'commission_rate': 2.5,
        'alert_quantity': 15,
        'expiry_date': '2027-11-30',
        'description': 'Triple-refined cholesterol-free pure sunflower cooking oil.',
        'quantity': 35,
      },
      {
        'id': 8,
        'category_id': 2, // Beverages
        'unit_id': 1,
        'brand_id': 3, // Nestle
        'name': 'Nescafe Classic Instant Coffee Jar (200g)',
        'slug': 'nescafe-classic-instant-coffee-200g',
        'sku': 'NES-COF-200G',
        'barcode': '789123456008',
        'cost_price': 4200.0,
        'sell_price': 5600.0,
        'tax_rate': 7.5,
        'commission_rate': 3.0,
        'alert_quantity': 10,
        'expiry_date': '2028-03-10',
        'description': '100% pure roasted coffee with a rich bold aroma.',
        'quantity': 22,
      },
    ];

    for (var p in products) {
      final pMap = Map<String, dynamic>.from(p);
      final qty = pMap.remove('quantity') as int;
      await db.insert('products', {
        ...pMap,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // Product store inventory
      await db.insert('product_store', {
        'product_id': pMap['id'],
        'store_id': 1,
        'quantity': qty,
        'alert_quantity': pMap['alert_quantity'],
        'created_at': now,
        'updated_at': now,
      });
    }

    // Seed Sample Initial Sale for Immediate Dashboard Analytics
    final saleInvoice = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    await db.insert('sales', {
      'id': 1,
      'store_id': 1,
      'user_id': 1,
      'customer_id': 1,
      'distributor_id': 1,
      'invoice_number': saleInvoice,
      'subtotal': 17700.0,
      'tax_amount': 315.0,
      'total': 18015.0,
      'paid': 20000.0,
      'change': 1985.0,
      'status': 'completed',
      'payment_method': 'cash',
      'sync_status': 'synced',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('sale_items', {
      'sale_id': 1,
      'product_id': 1,
      'product_name': 'Golden Harvest Royal Basmati Rice (5kg)',
      'product_sku': 'GH-RICE-5KG',
      'quantity': 1,
      'unit_price': 13500.0,
      'subtotal': 13500.0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('sale_items', {
      'sale_id': 1,
      'product_id': 2,
      'product_name': 'Coca-Cola Zero Sugar (50cl Bottle - Pack of 12)',
      'product_sku': 'CC-ZERO-50CL-PK',
      'quantity': 1,
      'unit_price': 4200.0,
      'subtotal': 4200.0,
      'created_at': now,
      'updated_at': now,
    });

    // Seed Distributor Commission for this sale
    await db.insert('commissions', {
      'id': 1,
      'sale_id': 1,
      'sale_item_id': 1,
      'distributor_id': 1,
      'product_id': 1,
      'product_name': 'Golden Harvest Royal Basmati Rice (5kg)',
      'product_sku': 'GH-RICE-5KG',
      'quantity': 1,
      'cost_price': 11000.0,
      'sell_price': 13500.0,
      'profit_per_unit': 2500.0,
      'commission_rate': 2.5,
      'commission_amount': 337.5,
      'status': 'earned',
      'created_at': now,
      'updated_at': now,
    });

    // Seed Sample Expense
    await db.insert('expenses', {
      'id': 1,
      'store_id': 1,
      'user_id': 1,
      'description': 'Supermarket Store Utility & Generator Diesel',
      'amount': 8500.0,
      'type': 'expense',
      'note': 'Routine store maintenance and power supply',
      'created_at': now,
      'updated_at': now,
    });
  }

  // --- User Queries ---
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ? AND is_active = 1',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePassword(int userId, String newHashedPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'password': newHashedPassword,
        'must_change_password': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'id ASC');
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Product & Inventory Queries ---
  Future<List<Map<String, dynamic>>> getProductsWithInventory({String query = '', int? categoryId}) async {
    final db = await database;
    String sql = '''
      SELECT 
        p.*,
        COALESCE(ps.quantity, 0) as quantity,
        c.name as category_name,
        b.name as brand_name,
        u.short_name as unit_name
      FROM products p
      LEFT JOIN product_store ps ON p.id = ps.product_id
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN units u ON p.unit_id = u.id
      WHERE p.is_active = 1
    ''';

    final params = <dynamic>[];
    if (query.isNotEmpty) {
      sql += ' AND (p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)';
      params.addAll(['%$query%', '%$query%', '%$query%']);
    }
    if (categoryId != null && categoryId > 0) {
      sql += ' AND p.category_id = ?';
      params.add(categoryId);
    }
    sql += ' ORDER BY p.name ASC';

    return await db.rawQuery(sql, params);
  }

  Future<int> insertProduct(Map<String, dynamic> product, int initialQuantity) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final pMap = Map<String, dynamic>.from(product);
      pMap['created_at'] = now;
      pMap['updated_at'] = now;

      final productId = await txn.insert('products', pMap);

      await txn.insert('product_store', {
        'product_id': productId,
        'store_id': 1,
        'quantity': initialQuantity,
        'alert_quantity': product['alert_quantity'] ?? 10,
        'created_at': now,
        'updated_at': now,
      });

      return productId;
    });
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product, int quantity) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final pMap = Map<String, dynamic>.from(product);
      pMap['updated_at'] = now;

      await txn.update('products', pMap, where: 'id = ?', whereArgs: [id]);

      await txn.rawInsert('''
        INSERT INTO product_store (product_id, store_id, quantity, alert_quantity, created_at, updated_at)
        VALUES (?, 1, ?, ?, ?, ?)
        ON CONFLICT(product_id, store_id) DO UPDATE SET
          quantity = excluded.quantity,
          alert_quantity = excluded.alert_quantity,
          updated_at = excluded.updated_at
      ''', [id, quantity, product['alert_quantity'] ?? 10, now, now]);

      return 1;
    });
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.update('products', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Sales & POS Queries ---
  Future<int> createSale({
    required Map<String, dynamic> saleData,
    required List<Map<String, dynamic>> items,
    int? distributorId,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final sMap = Map<String, dynamic>.from(saleData);
      sMap['created_at'] = now;
      sMap['updated_at'] = now;

      final saleId = await txn.insert('sales', sMap);

      for (var item in items) {
        final itemMap = Map<String, dynamic>.from(item);
        itemMap['sale_id'] = saleId;
        itemMap['created_at'] = now;
        itemMap['updated_at'] = now;

        final productId = itemMap['product_id'] as int;
        final qty = itemMap['quantity'] as int;

        final saleItemId = await txn.insert('sale_items', itemMap);

        // Deduct inventory
        await txn.rawUpdate('''
          UPDATE product_store 
          SET quantity = MAX(0, quantity - ?), updated_at = ?
          WHERE product_id = ? AND store_id = 1
        ''', [qty, now, productId]);

        // Compute distributor commission if sale has distributor
        if (distributorId != null && distributorId > 0) {
          final prodRows = await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1);
          if (prodRows.isNotEmpty) {
            final prod = prodRows.first;
            final commRate = (prod['commission_rate'] as num?)?.toDouble() ?? 0.0;
            if (commRate > 0) {
              final sellPrice = (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0;
              final costPrice = (prod['cost_price'] as num?)?.toDouble() ?? 0.0;
              final profitPerUnit = sellPrice - costPrice;
              final commAmount = (profitPerUnit > 0 ? (profitPerUnit * commRate / 100) : 0.0) * qty;

              await txn.insert('commissions', {
                'sale_id': saleId,
                'sale_item_id': saleItemId,
                'distributor_id': distributorId,
                'product_id': productId,
                'product_name': itemMap['product_name'],
                'product_sku': itemMap['product_sku'],
                'quantity': qty,
                'cost_price': costPrice,
                'sell_price': sellPrice,
                'profit_per_unit': profitPerUnit,
                'commission_rate': commRate,
                'commission_amount': commAmount,
                'status': 'earned',
                'created_at': now,
                'updated_at': now,
              });
            }
          }
        }
      }

      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getSales({int limit = 50}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        u.name as cashier_name,
        d.name as distributor_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN distributors d ON s.distributor_id = d.id
      ORDER BY s.id DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await database;
    return await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  // --- Purchases Queries ---
  Future<int> createPurchase({
    required Map<String, dynamic> purchaseData,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final pMap = Map<String, dynamic>.from(purchaseData);
      pMap['created_at'] = now;
      pMap['updated_at'] = now;

      final purchaseId = await txn.insert('purchases', pMap);

      for (var item in items) {
        final itemMap = Map<String, dynamic>.from(item);
        itemMap['purchase_id'] = purchaseId;
        itemMap['created_at'] = now;
        itemMap['updated_at'] = now;

        final productId = itemMap['product_id'] as int;
        final qty = itemMap['quantity'] as int;
        final cost = (itemMap['cost_price'] as num).toDouble();

        await txn.insert('purchase_items', itemMap);

        // Add inventory & update cost price
        await txn.rawUpdate('''
          UPDATE product_store 
          SET quantity = quantity + ?, updated_at = ?
          WHERE product_id = ? AND store_id = 1
        ''', [qty, now, productId]);

        await txn.update(
          'products',
          {'cost_price': cost, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }

      return purchaseId;
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.*,
        s.name as supplier_name,
        u.name as user_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN users u ON p.user_id = u.id
      ORDER BY p.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        pi.*,
        p.name as product_name,
        p.sku as product_sku
      FROM purchase_items pi
      LEFT JOIN products p ON pi.product_id = p.id
      WHERE pi.purchase_id = ?
    ''', [purchaseId]);
  }

  // --- Auxiliary Queries: Categories, Brands, Units, Suppliers, Customers ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> c) async {
    final db = await database;
    return await db.insert('categories', c);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> c) async {
    final db = await database;
    return await db.update('categories', c, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final db = await database;
    return await db.query('brands', orderBy: 'name ASC');
  }

  Future<int> insertBrand(Map<String, dynamic> b) async {
    final db = await database;
    return await db.insert('brands', b);
  }

  Future<int> updateBrand(int id, Map<String, dynamic> b) async {
    final db = await database;
    return await db.update('brands', b, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBrand(int id) async {
    final db = await database;
    return await db.delete('brands', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnits() async {
    final db = await database;
    return await db.query('units', orderBy: 'name ASC');
  }

  Future<int> insertUnit(Map<String, dynamic> u) async {
    final db = await database;
    return await db.insert('units', u);
  }

  Future<int> updateUnit(int id, Map<String, dynamic> u) async {
    final db = await database;
    return await db.update('units', u, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUnit(int id) async {
    final db = await database;
    return await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<int> insertCustomer(Map<String, dynamic> c) async {
    final db = await database;
    return await db.insert('customers', c);
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> c) async {
    final db = await database;
    return await db.update('customers', c, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<int> insertSupplier(Map<String, dynamic> s) async {
    final db = await database;
    return await db.insert('suppliers', s);
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> s) async {
    final db = await database;
    return await db.update('suppliers', s, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Distributors & Commissions ---
  Future<List<Map<String, dynamic>>> getDistributors() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        d.*,
        COALESCE(SUM(c.commission_amount), 0) as total_earned,
        COALESCE((SELECT SUM(amount) FROM commission_payments WHERE distributor_id = d.id), 0) as total_paid
      FROM distributors d
      LEFT JOIN commissions c ON d.id = c.distributor_id
      GROUP BY d.id
      ORDER BY d.name ASC
    ''');
  }

  Future<int> insertDistributor(Map<String, dynamic> d) async {
    final db = await database;
    return await db.insert('distributors', d);
  }

  Future<int> updateDistributor(int id, Map<String, dynamic> d) async {
    final db = await database;
    return await db.update('distributors', d, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDistributorCommissions(int distributorId) async {
    final db = await database;
    return await db.query(
      'commissions',
      where: 'distributor_id = ?',
      whereArgs: [distributorId],
      orderBy: 'id DESC',
    );
  }

  Future<int> recordCommissionPayment(int distributorId, double amount, String reference, String note, int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('commission_payments', {
      'distributor_id': distributorId,
      'amount': amount,
      'reference': reference,
      'note': note,
      'paid_by': userId,
      'paid_at': now,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getCommissionPayments(int distributorId) async {
    final db = await database;
    return await db.query(
      'commission_payments',
      where: 'distributor_id = ?',
      whereArgs: [distributorId],
      orderBy: 'id DESC',
    );
  }

  // --- Expenses Queries ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.*, u.name as logged_by_name
      FROM expenses e
      LEFT JOIN users u ON e.user_id = u.id
      ORDER BY e.id DESC
    ''');
  }

  Future<int> insertExpense(Map<String, dynamic> e) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('expenses', {
      ...e,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reports & Dashboard Metrics ---
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await database;

    // Total sales revenue
    final salesRes = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as total_sales, COUNT(*) as sales_count FROM sales');
    final totalSales = (salesRes.first['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (salesRes.first['sales_count'] as num?)?.toInt() ?? 0;

    // Total products & low stock
    final prodRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_products,
        COALESCE(SUM(CASE WHEN ps.quantity <= ps.alert_quantity THEN 1 ELSE 0 END), 0) as low_stock_count,
        COALESCE(SUM(ps.quantity * p.cost_price), 0) as inventory_value
      FROM products p
      LEFT JOIN product_store ps ON p.id = ps.product_id
      WHERE p.is_active = 1
    ''');
    final totalProducts = (prodRes.first['total_products'] as num?)?.toInt() ?? 0;
    final lowStockCount = (prodRes.first['low_stock_count'] as num?)?.toInt() ?? 0;
    final inventoryValue = (prodRes.first['inventory_value'] as num?)?.toDouble() ?? 0.0;

    // Near expiry count (within 30 days)
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30)).toIso8601String().substring(0, 10);
    final expiryRes = await db.rawQuery('''
      SELECT COUNT(*) as near_expiry_count
      FROM products
      WHERE is_active = 1 AND expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date <= ?
    ''', [in30Days]);
    final nearExpiryCount = (expiryRes.first['near_expiry_count'] as num?)?.toInt() ?? 0;

    // Total expenses
    final expRes = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) as total_expenses FROM expenses');
    final totalExpenses = (expRes.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

    // Estimated profit (Sales subtotal - Cost of goods sold - Expenses)
    final cogsRes = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity * p.cost_price), 0) as total_cogs
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
    ''');
    final totalCogs = (cogsRes.first['total_cogs'] as num?)?.toDouble() ?? 0.0;
    final grossProfit = totalSales - totalCogs;
    final netProfit = grossProfit - totalExpenses;

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'near_expiry_count': nearExpiryCount,
      'inventory_value': inventoryValue,
      'total_expenses': totalExpenses,
      'total_cogs': totalCogs,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
    };
  }

  // --- Advanced Reporting Queries ---

  /// Returns sales totals grouped by day for the last [days] days.
  /// Result: [{date: 'YYYY-MM-DD', total: double, orders: int}, ...]
  Future<List<Map<String, dynamic>>> getWeeklySales({int days = 7}) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days - 1));
    final startStr = '${startDate.year.toString().padLeft(4, '0')}-'
        '${startDate.month.toString().padLeft(2, '0')}-'
        '${startDate.day.toString().padLeft(2, '0')}';
    return await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total), 0) as total,
        COUNT(*) as orders
      FROM sales
      WHERE DATE(created_at) >= ?
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [startStr]);
  }

  /// Returns the top [limit] best-selling products by quantity sold.
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 10}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.name,
        p.sku,
        COALESCE(SUM(si.quantity), 0) as total_qty,
        COALESCE(SUM(si.subtotal), 0) as total_revenue
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      GROUP BY si.product_id
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Returns sales list filtered by optional date range.
  Future<List<Map<String, dynamic>>> getSalesByDateRange({
    String? from,
    String? to,
    int limit = 200,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (from != null && from.isNotEmpty) {
      conditions.add("DATE(s.created_at) >= ?");
      args.add(from);
    }
    if (to != null && to.isNotEmpty) {
      conditions.add("DATE(s.created_at) <= ?");
      args.add(to);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    args.add(limit);

    return await db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        u.name as cashier_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN users u ON s.user_id = u.id
      $whereClause
      ORDER BY s.id DESC
      LIMIT ?
    ''', args);
  }

  /// Dashboard metrics scoped to a date range. Pass null for all-time.
  Future<Map<String, dynamic>> getDashboardMetricsForPeriod({
    String? from,
    String? to,
  }) async {
    final db = await database;

    final dateCond = StringBuffer();
    final args = <dynamic>[];
    if (from != null && from.isNotEmpty) {
      dateCond.write(' AND DATE(created_at) >= ?');
      args.add(from);
    }
    if (to != null && to.isNotEmpty) {
      dateCond.write(' AND DATE(created_at) <= ?');
      args.add(to);
    }

    final salesRes = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) as total_sales, COUNT(*) as sales_count FROM sales WHERE 1=1${dateCond.toString()}',
      args,
    );
    final totalSales = (salesRes.first['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (salesRes.first['sales_count'] as num?)?.toInt() ?? 0;

    final cogsArgs = List<dynamic>.from(args);
    final cogsRes = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity * p.cost_price), 0) as total_cogs
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      WHERE 1=1${dateCond.toString()}
    ''', cogsArgs);
    final totalCogs = (cogsRes.first['total_cogs'] as num?)?.toDouble() ?? 0.0;

    final expArgs = List<dynamic>.from(args);
    final expRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total_expenses FROM expenses WHERE 1=1${dateCond.toString()}',
      expArgs,
    );
    final totalExpenses = (expRes.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

    final grossProfit = totalSales - totalCogs;
    final netProfit = grossProfit - totalExpenses;

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'total_cogs': totalCogs,
      'total_expenses': totalExpenses,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
    };
  }

  // --- Settings ---
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (var r in rows) {
      map[r['key'] as String] = r['value'] as String? ?? '';
    }
    return map;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO settings (key, value, created_at, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
    ''', [key, value, now, now]);
  }
}
