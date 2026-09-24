import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAdjustStockDialog(ProductModel product) {
    final qtyCtrl = TextEditingController(text: product.quantity.toString());
    final provider = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Adjust Stock: ${product.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(labelText: 'New Stock Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              final newQty = int.tryParse(qtyCtrl.text) ?? product.quantity;
              await provider.updateProduct(product.id, product.toMap(), newQty);
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    final lowStockItems = provider.products.where((p) => p.isLowStock).toList();
    final expiryItems = provider.products.where((p) => p.expiryDate != null && p.expiryDate!.isNotEmpty).toList()
      ..sort((a, b) => (a.expiryDate ?? '').compareTo(b.expiryDate ?? ''));

    final totalStockQty = provider.products.fold(0, (sum, p) => sum + p.quantity);
    final totalStockValuation = provider.products.fold(0.0, (sum, p) => sum + (p.quantity * p.costPrice));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Bar
            Row(
              children: [
                _buildSummaryBadge('Total Units', '$totalStockQty pcs', AppTheme.primaryGreen),
                const SizedBox(width: 12),
                _buildSummaryBadge('Inventory Value', Formatters.formatCurrency(totalStockValuation, symbol: symbol), AppTheme.infoSky),
                const SizedBox(width: 12),
                _buildSummaryBadge('Low Stock Alerts', '${lowStockItems.length} items', AppTheme.warningAmber),
                const SizedBox(width: 12),
                _buildSummaryBadge('Expiry Warnings', '${provider.totalExpiredCount + provider.totalNearExpiryCount} items', AppTheme.dangerRed),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textDarkSecondary,
              tabs: [
                Tab(
                  icon: Badge(
                    isLabelVisible: lowStockItems.isNotEmpty,
                    label: Text('${lowStockItems.length}'),
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  text: 'Low Stock Alerts',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: (provider.totalExpiredCount + provider.totalNearExpiryCount) > 0,
                    label: Text('${provider.totalExpiredCount + provider.totalNearExpiryCount}'),
                    child: const Icon(Icons.event_busy_rounded),
                  ),
                  text: 'Expiry Tracker',
                ),
                const Tab(
                  icon: Icon(Icons.inventory_2_rounded),
                  text: 'All Stock Levels',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Low stock
                  _buildProductList(lowStockItems, symbol, isLowStockView: true),
                  // Tab 2: Expiry
                  _buildProductList(expiryItems, symbol, isExpiryView: true),
                  // Tab 3: All
                  _buildProductList(provider.products, symbol),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductModel> items, String symbol, {bool isLowStockView = false, bool isExpiryView = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.successGreen.withValues(alpha:0.6), size: 48),
            const SizedBox(height: 8),
            Text(
              isLowStockView
                  ? 'All products are well stocked!'
                  : (isExpiryView ? 'No products with expiry dates recorded.' : 'No items found.'),
              style: const TextStyle(color: AppTheme.textDarkSecondary),
            ),
          ],
        ),
      );
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
          final p = items[index];

          Color statusColor = AppTheme.successGreen;
          String statusText = 'Normal';
          if (p.quantity <= 0) {
            statusColor = AppTheme.dangerRed;
            statusText = 'OUT OF STOCK';
          } else if (p.isLowStock) {
            statusColor = AppTheme.warningAmber;
            statusText = 'LOW STOCK (${p.quantity}/${p.alertQuantity})';
          }

          if (isExpiryView) {
            if (p.isExpired) {
              statusColor = AppTheme.dangerRed;
              statusText = 'EXPIRED (${p.expiryDate})';
            } else if (p.isNearExpiry) {
              statusColor = AppTheme.warningAmber;
              statusText = 'EXPIRING SOON (${p.expiryDate})';
            } else {
              statusColor = AppTheme.successGreen;
              statusText = 'Expires: ${p.expiryDate}';
            }
          }

          return ListTile(
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            subtitle: Text('SKU: ${p.sku} • Cost: ${Formatters.formatCurrency(p.costPrice, symbol: symbol)} • Sell: ${Formatters.formatCurrency(p.sellPrice, symbol: symbol)}',
                style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha:0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryMint, size: 20),
                  tooltip: 'Adjust Stock',
                  onPressed: () => _showAdjustStockDialog(p),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
