import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/barcode_scanner_dialog.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import 'contacts/contacts_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'distributors/distributors_screen.dart';
import 'expenses/expenses_screen.dart';
import 'inventory/inventory_screen.dart';
import 'pos/pos_screen.dart';
import 'products/products_screen.dart';
import 'purchases/purchases_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/sales_screen.dart';
import 'settings/settings_screen.dart';

class NavigationTabItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final int? badgeCount;

  NavigationTabItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    this.badgeCount,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final totalAlerts = productProvider.totalLowStockCount + productProvider.totalNearExpiryCount;

    // Role-based Navigation Tabs
    final List<NavigationTabItem> tabs = [];

    if (user.isManager) {
      tabs.add(NavigationTabItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        screen: const DashboardScreen(),
      ));
    }

    tabs.add(NavigationTabItem(
      title: 'POS Terminal',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      screen: const PosScreen(),
    ));

    if (user.isManager) {
      tabs.add(NavigationTabItem(
        title: 'Products',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        screen: const ProductsScreen(),
      ));
    }

    tabs.add(NavigationTabItem(
      title: 'Sales History',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      screen: const SalesScreen(),
    ));

    tabs.add(NavigationTabItem(
      title: 'Inventory & Alerts',
      icon: Icons.notifications_active_outlined,
      selectedIcon: Icons.notifications_active_rounded,
      badgeCount: totalAlerts,
      screen: const InventoryScreen(),
    ));

    if (user.isManager) {
      tabs.add(NavigationTabItem(
        title: 'Purchases',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag_rounded,
        screen: const PurchasesScreen(),
      ));

      tabs.add(NavigationTabItem(
        title: 'Contacts CRM',
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt_rounded,
        screen: const ContactsScreen(),
      ));

      tabs.add(NavigationTabItem(
        title: 'Distributors',
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping_rounded,
        screen: const DistributorsScreen(),
      ));

      tabs.add(NavigationTabItem(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        screen: const ExpensesScreen(),
      ));
    }

    tabs.add(NavigationTabItem(
      title: 'Reports & BI',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      screen: const ReportsScreen(),
    ));

    if (user.isAdmin) {
      tabs.add(NavigationTabItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        screen: const SettingsScreen(),
      ));
    }

    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final currentTab = tabs[_selectedIndex];

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildMobileDrawer(context, tabs, user, auth, settings) : null,
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: AppTheme.bgDarkCard,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/logo_icon.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: AppTheme.primaryGreen, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentTab.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryMint),
                  tooltip: 'Scan Barcode',
                  onPressed: () async {
                    final scannedCode = await BarcodeScannerDialog.show(context);
                    if (scannedCode != null && context.mounted) {
                      final pos = Provider.of<PosProvider>(context, listen: false);
                      final product = productProvider.findByBarcodeOrSku(scannedCode);
                      if (product != null) {
                        pos.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${product.name}" to cart'),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Barcode "$scannedCode" not found'),
                            backgroundColor: AppTheme.dangerRed,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _buildDesktopNavigationRail(context, tabs, user, auth, settings, screenWidth),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: tabs.map((t) => t.screen).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavigationRail(
    BuildContext context,
    List<NavigationTabItem> tabs,
    UserModel user,
    AuthProvider auth,
    SettingsProvider settings,
    double screenWidth,
  ) {
    final isExtended = screenWidth >= 1150;

    return Container(
      width: isExtended ? 250 : 80,
      decoration: const BoxDecoration(
        color: AppTheme.bgDarkCard,
        border: Border(right: BorderSide(color: AppTheme.borderDark, width: 1)),
      ),
      child: Column(
        children: [
          // App Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 8, vertical: 20),
            child: Row(
              mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.4), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 24),
                  ),
                ),
                if (isExtended) ...[
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JIMS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1),
                      ),
                      Text(
                        'Jeilo Inventory System',
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryMint, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderDark),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExtended ? 16 : 0,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withValues(alpha:0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.5), width: 1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Badge(
                            isLabelVisible: (tab.badgeCount ?? 0) > 0,
                            label: Text('${tab.badgeCount}'),
                            backgroundColor: AppTheme.dangerRed,
                            child: Icon(
                              isSelected ? tab.selectedIcon : tab.icon,
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.textDarkSecondary,
                              size: 22,
                            ),
                          ),
                          if (isExtended) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                tab.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppTheme.textDarkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderDark),

          // User Profile & Logout at bottom
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: isExtended
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha:0.2),
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: user.isAdmin ? AppTheme.warningAmber : AppTheme.primaryMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed, size: 20),
                        tooltip: 'Logout',
                        onPressed: () => auth.logout(),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed),
                    tooltip: 'Logout (${user.name})',
                    onPressed: () => auth.logout(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    List<NavigationTabItem> tabs,
    UserModel user,
    AuthProvider auth,
    SettingsProvider settings,
  ) {
    return Drawer(
      backgroundColor: AppTheme.bgDarkCard,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/logo_icon.png',
                errorBuilder: (_, __, ___) => const Text(
                  'J',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Row(
              children: [
                Text(user.email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Badge(
                    isLabelVisible: (tab.badgeCount ?? 0) > 0,
                    label: Text('${tab.badgeCount}'),
                    backgroundColor: AppTheme.dangerRed,
                    child: Icon(
                      isSelected ? tab.selectedIcon : tab.icon,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textDarkSecondary,
                    ),
                  ),
                  title: Text(
                    tab.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryGreen.withValues(alpha:0.1),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          const Divider(color: AppTheme.borderDark),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed),
            title: const Text('Logout', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.of(context).pop();
              auth.logout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
