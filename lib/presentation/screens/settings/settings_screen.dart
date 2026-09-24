import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _symbolCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _expiryCtrl;
  late TextEditingController _footerCtrl;

  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final s = Provider.of<SettingsProvider>(context, listen: false);

    _nameCtrl = TextEditingController(text: s.storeName);
    _phoneCtrl = TextEditingController(text: s.storePhone);
    _emailCtrl = TextEditingController(text: s.storeEmail);
    _addressCtrl = TextEditingController(text: s.storeAddress);
    _symbolCtrl = TextEditingController(text: s.currencySymbol);
    _taxCtrl = TextEditingController(text: s.taxRate.toString());
    _expiryCtrl = TextEditingController(text: s.expiryAlertDays.toString());
    _footerCtrl = TextEditingController(text: s.receiptFooter);

    _loadUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _symbolCtrl.dispose();
    _taxCtrl.dispose();
    _expiryCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final rows = await DatabaseHelper.instance.getUsers();
    setState(() {
      _users = rows;
      _isLoadingUsers = false;
    });
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController(text: 'password');
    String selectedRole = 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.bgDarkCard,
          title: const Text('Add System User', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email Address *')),
              const SizedBox(height: 8),
              TextField(controller: pwdCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Initial Password')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: AppTheme.bgDarkCard,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Role / Access Level'),
                items: [
                  const DropdownMenuItem(value: 'cashier', child: Text('Cashier (POS Only)')),
                  const DropdownMenuItem(value: 'manager', child: Text('Store Manager (Inventory & Sales)')),
                  const DropdownMenuItem(value: 'admin', child: Text('Administrator (Full Control)')),
                ],
                onChanged: (val) => setDlgState(() => selectedRole = val ?? 'cashier'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final pwd = pwdCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) return;

                final now = DateTime.now().toIso8601String();
                final hash = PasswordHasher.hash(pwd);

                await DatabaseHelper.instance.createUser({
                  'store_id': 1,
                  'name': name,
                  'email': email,
                  'password': hash,
                  'role': selectedRole,
                  'is_active': 1,
                  'must_change_password': 0,
                  'created_at': now,
                  'updated_at': now,
                });

                await _loadUsers();
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStoreSettings() async {
    final s = Provider.of<SettingsProvider>(context, listen: false);
    await s.updateSetting('store_name', _nameCtrl.text.trim());
    await s.updateSetting('store_phone', _phoneCtrl.text.trim());
    await s.updateSetting('store_email', _emailCtrl.text.trim());
    await s.updateSetting('store_address', _addressCtrl.text.trim());
    await s.updateSetting('currency_symbol', _symbolCtrl.text.trim());
    await s.updateSetting('tax_rate', _taxCtrl.text.trim());
    await s.updateSetting('expiry_alert_days', _expiryCtrl.text.trim());
    await s.updateSetting('receipt_footer', _footerCtrl.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: AppTheme.successGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Settings & Configuration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textDarkSecondary,
              tabs: const [
                Tab(text: 'Store Profile & Receipts'),
                Tab(text: 'User Accounts (RBAC)'),
                Tab(text: 'Database & About JIMS'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Store Profile
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Store Identification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Store Name'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone Number'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email Address'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _addressCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Store Location Address'))),
                            ],
                          ),
                          const Divider(color: AppTheme.borderDark, height: 28),
                          const Text('Localization & Receipt Format', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _symbolCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. ₦, \$, €)'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _taxCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Default Tax / VAT %'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _expiryCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Expiry Warning Threshold (Days)'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _footerCtrl,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Thermal Receipt Footer Note'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Save Settings'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            onPressed: _saveStoreSettings,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Users Management
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDarkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Active System Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text('Add User'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                              onPressed: _showAddUserDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _isLoadingUsers
                              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                              : ListView.separated(
                                  itemCount: _users.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                                  itemBuilder: (context, index) {
                                    final u = _users[index];
                                    final role = (u['role'] as String? ?? 'cashier').toUpperCase();
                                    final isCurrentUser = u['id'] == user?.id;

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: role == 'ADMIN' ? AppTheme.warningAmber.withValues(alpha:0.2) : AppTheme.primaryGreen.withValues(alpha:0.2),
                                        child: Text(
                                          (u['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: role == 'ADMIN' ? AppTheme.warningAmber : AppTheme.primaryMint,
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha:0.2), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('YOU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryMint)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Text('${u['email']} • Role: $role', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                                      trailing: isCurrentUser
                                          ? null
                                          : IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 18),
                                              tooltip: 'Delete User',
                                              onPressed: () async {
                                                await DatabaseHelper.instance.deleteUser(u['id']);
                                                await _loadUsers();
                                              },
                                            ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: About & Architecture
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDarkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.4)),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/images/logo_icon.png',
                                errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGreen, size: 36),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('JIMS - Jeilo Inventory Management System', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('Version 1.0.0 (Release Build)', style: TextStyle(color: AppTheme.primaryMint, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.borderDark),
                        const SizedBox(height: 12),
                        const Text('Platform & Architecture Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('• Offline-First Standalone Engine: Local SQLite with FFI native acceleration & IndexedDB WebAssembly on Web.', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                        const Text('• Multi-Platform Target: Desktop (Windows, macOS, Linux), Mobile (Android min 11, iOS), and Web PWA.', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                        const Text('• Hardware Ready: Camera barcode/QR scanner, 80mm/58mm thermal receipt printing, and ESC-POS support.', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                        const Text('• Cloud-Ready Design: Clean provider architecture structured for cloud synchronization in future phases.', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
