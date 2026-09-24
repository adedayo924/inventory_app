import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auxiliary_models.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<CustomerModel> _customers = [];
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final cRows = await db.getCustomers();
    final sRows = await db.getSuppliers();
    setState(() {
      _customers = cRows.map((r) => CustomerModel.fromMap(r)).toList();
      _suppliers = sRows.map((r) => SupplierModel.fromMap(r)).toList();
      _isLoading = false;
    });
  }

  void _showAddCustomerDialog([CustomerModel? c]) {
    final nameCtrl = TextEditingController(text: c?.name ?? '');
    final phoneCtrl = TextEditingController(text: c?.phone ?? '');
    final emailCtrl = TextEditingController(text: c?.email ?? '');
    final addrCtrl = TextEditingController(text: c?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        title: Text(c != null ? 'Edit Customer' : 'Add Customer', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };
              if (c != null) {
                await DatabaseHelper.instance.updateCustomer(c.id, data);
              } else {
                await DatabaseHelper.instance.insertCustomer(data);
              }
              await _loadContacts();
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog([SupplierModel? s]) {
    final nameCtrl = TextEditingController(text: s?.name ?? '');
    final phoneCtrl = TextEditingController(text: s?.phone ?? '');
    final emailCtrl = TextEditingController(text: s?.email ?? '');
    final addrCtrl = TextEditingController(text: s?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        title: Text(s != null ? 'Edit Supplier' : 'Add Supplier', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Company / Name *')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              };
              if (s != null) {
                await DatabaseHelper.instance.updateSupplier(s.id, data);
              } else {
                await DatabaseHelper.instance.insertSupplier(data);
              }
              await _loadContacts();
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contacts Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(_tabCtrl.index == 0 ? 'Add Customer' : 'Add Supplier'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () {
                    if (_tabCtrl.index == 0) {
                      _showAddCustomerDialog();
                    } else {
                      _showAddSupplierDialog();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textDarkSecondary,
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: 'Retail Customers (${_customers.length})'),
                Tab(text: 'Wholesale Suppliers (${_suppliers.length})'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Customers
                        _buildContactsList(
                          _customers.map((c) => {
                            'title': c.name,
                            'phone': c.phone,
                            'email': c.email,
                            'address': c.address,
                            'model': c,
                          }).toList(),
                          isCustomer: true,
                        ),
                        // Suppliers
                        _buildContactsList(
                          _suppliers.map((s) => {
                            'title': s.name,
                            'phone': s.phone,
                            'email': s.email,
                            'address': s.address,
                            'model': s,
                          }).toList(),
                          isCustomer: false,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(List<Map<String, dynamic>> items, {required bool isCustomer}) {
    if (items.isEmpty) {
      return const Center(child: Text('No contacts found', style: TextStyle(color: AppTheme.textDarkSecondary)));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isCustomer ? AppTheme.primaryGreen.withValues(alpha:0.15) : AppTheme.infoSky.withValues(alpha:0.15),
              child: Icon(
                isCustomer ? Icons.person_rounded : Icons.store_mall_directory_rounded,
                color: isCustomer ? AppTheme.primaryMint : AppTheme.infoSky,
              ),
            ),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            subtitle: Text('Tel: ${item['phone'] ?? "N/A"} • ${item['address'] ?? ""}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryMint, size: 20),
              onPressed: () {
                if (isCustomer) {
                  _showAddCustomerDialog(item['model'] as CustomerModel);
                } else {
                  _showAddSupplierDialog(item['model'] as SupplierModel);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
