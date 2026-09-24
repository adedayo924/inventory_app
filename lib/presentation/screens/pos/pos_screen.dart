import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/barcode_scanner_dialog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_pdf_generator.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/distributors_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _mobileTabController;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mobileTabController?.dispose();
    super.dispose();
  }

  void _onBarcodeScan() async {
    final scannedCode = await BarcodeScannerDialog.show(context);
    if (scannedCode != null && mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final posProvider = Provider.of<PosProvider>(context, listen: false);

      final p = productProvider.findByBarcodeOrSku(scannedCode);
      if (p != null) {
        if (p.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: "${p.name}" is out of stock!'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        } else {
          posProvider.addToCart(p);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${p.name}" to cart'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product matched barcode "$scannedCode"'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final posProvider = Provider.of<PosProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);
    final distProvider = Provider.of<DistributorsProvider>(context);
    final reportsProvider = Provider.of<ReportsProvider>(context);

    final symbol = settings.currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    // Product Grid Catalog
    final productGridWidget = Column(
      children: [
        // Top Search Bar & Category Chips
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.bgDarkCard,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search product by Name, SKU or Barcode...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textDarkSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textDarkSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => productProvider.setSearchQuery(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.4)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGreen),
                      tooltip: 'Scan Barcode with Camera',
                      onPressed: _onBarcodeScan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All Products', null, productProvider),
                    ...productProvider.categories.map(
                      (cat) => _buildCategoryChip(cat.name, cat.id, productProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Product Catalog Cards
        Expanded(
          child: productProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
              : productProvider.products.isEmpty
                  ? const Center(
                      child: Text(
                        'No retail products found.',
                        style: TextStyle(color: AppTheme.textDarkSecondary),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final gridWidth = constraints.maxWidth;
                        final crossCount = gridWidth > 800 ? 3 : (gridWidth > 450 ? 2 : 1);

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final p = productProvider.products[index];
                            final isOutOfStock = p.quantity <= 0;

                            return InkWell(
                              onTap: isOutOfStock
                                  ? null
                                  : () {
                                      posProvider.addToCart(p);
                                    },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDarkCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: p.isLowStock
                                        ? AppTheme.warningAmber.withValues(alpha:0.4)
                                        : AppTheme.borderDark,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock
                                                ? AppTheme.dangerRed.withValues(alpha:0.2)
                                                : (p.isLowStock ? AppTheme.warningAmber.withValues(alpha:0.2) : AppTheme.primaryGreen.withValues(alpha:0.2)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${p.quantity} ${p.unitName ?? "pcs"}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? AppTheme.dangerRed
                                                  : (p.isLowStock ? AppTheme.warningAmber : AppTheme.primaryMint),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.sku,
                                              style: const TextStyle(fontSize: 10, color: AppTheme.textDarkMuted),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(p.sellPrice, symbol: symbol),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.primaryMint,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock ? AppTheme.bgDarkCardHover : AppTheme.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isOutOfStock ? Icons.block : Icons.add_shopping_cart_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );

    // Cart Panel Widget
    final cartPanelWidget = Container(
      color: AppTheme.bgDarkCard,
      child: Column(
        children: [
          // Cart Header & Customer Selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Current Order (${posProvider.totalItemCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                    if (posProvider.cart.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.dangerRed, size: 18),
                        label: const Text('Clear', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                        onPressed: () => posProvider.clearCart(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Distributor attribution for commissions
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: posProvider.selectedDistributorId,
                        isDense: true,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Commission Agent / Distributor',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Direct / None')),
                          ...distProvider.distributors.map(
                            (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                          ),
                        ],
                        onChanged: (val) {
                          final match = distProvider.distributors.where((d) => d.id == val).firstOrNull;
                          posProvider.setDistributor(val, match?.name);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: posProvider.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textDarkMuted),
                        SizedBox(height: 8),
                        Text(
                          'Cart is empty',
                          style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 14),
                        ),
                        Text(
                          'Scan barcode or tap products to add',
                          style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posProvider.cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                    itemBuilder: (context, index) {
                      final item = posProvider.cart[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(item.customPrice, symbol: symbol),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryMint),
                                  ),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textDarkSecondary, size: 20),
                                  onPressed: () => posProvider.updateQuantity(item.product.id, item.quantity - 1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20),
                                  onPressed: () => posProvider.updateQuantity(item.product.id, item.quantity + 1),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                Formatters.formatCurrency(item.subtotal, symbol: symbol),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Cart Financial Summary & Checkout Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              border: Border(top: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                    Text(Formatters.formatCurrency(posProvider.subtotal, symbol: symbol), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                if (posProvider.taxTotal > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT / Tax:', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                      Text(Formatters.formatCurrency(posProvider.taxTotal, symbol: symbol), style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ],
                const Divider(color: AppTheme.borderDark, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PAYABLE:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    Text(
                      Formatters.formatCurrency(posProvider.grandTotal, symbol: symbol),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: posProvider.cart.isEmpty
                        ? null
                        : () => _openCheckoutModal(
                              context,
                              posProvider,
                              auth.currentUser?.id ?? 1,
                              auth.currentUser?.name ?? 'Cashier',
                              settings,
                              productProvider,
                              salesProvider,
                              reportsProvider,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.point_of_sale_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Complete Sale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Responsive Return: Side-by-side on Desktop, Tabs on Mobile
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Row(
          children: [
            Expanded(flex: 6, child: productGridWidget),
            const VerticalDivider(width: 1, color: AppTheme.borderDark),
            Expanded(flex: 4, child: cartPanelWidget),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Column(
          children: [
            TabBar(
              controller: _mobileTabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textDarkSecondary,
              tabs: [
                const Tab(icon: Icon(Icons.grid_view_rounded), text: 'Products'),
                Tab(
                  icon: Badge(
                    isLabelVisible: posProvider.totalItemCount > 0,
                    label: Text('${posProvider.totalItemCount}'),
                    child: const Icon(Icons.shopping_cart_rounded),
                  ),
                  text: 'Cart',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _mobileTabController,
                children: [
                  productGridWidget,
                  cartPanelWidget,
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCategoryChip(String label, int? id, ProductProvider provider) {
    final isSelected = provider.selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        backgroundColor: AppTheme.bgDarkCardHover,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDarkSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => provider.setCategoryFilter(id),
      ),
    );
  }

  void _openCheckoutModal(
    BuildContext context,
    PosProvider posProvider,
    int userId,
    String cashierName,
    SettingsProvider settings,
    ProductProvider productProvider,
    SalesProvider salesProvider,
    ReportsProvider reportsProvider,
  ) {
    final total = posProvider.grandTotal;
    final symbol = settings.currencySymbol;
    final paidController = TextEditingController(text: total.toStringAsFixed(2));
    String paymentMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDarkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double paid = double.tryParse(paidController.text) ?? 0.0;
            final double change = (paid - total).clamp(0.0, double.infinity);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Process Payment',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textDarkSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Due Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('Amount Payable', style: TextStyle(color: AppTheme.primaryMint, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(total, symbol: symbol),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Selector
                  const Text('Payment Method:', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaymentTypeChip('cash', 'Cash', Icons.money_rounded, paymentMethod, (m) {
                        setModalState(() => paymentMethod = m);
                      }),
                      const SizedBox(width: 8),
                      _buildPaymentTypeChip('card', 'POS Card', Icons.credit_card_rounded, paymentMethod, (m) {
                        setModalState(() => paymentMethod = m);
                      }),
                      const SizedBox(width: 8),
                      _buildPaymentTypeChip('transfer', 'Transfer', Icons.account_balance_rounded, paymentMethod, (m) {
                        setModalState(() => paymentMethod = m);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Paid Amount Input
                  TextField(
                    controller: paidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount Received ($symbol)',
                      prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.primaryGreen),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Change Output
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change Due:', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 14)),
                      Text(
                        Formatters.formatCurrency(change, symbol: symbol),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: change >= 0 ? AppTheme.primaryMint : AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Confirm Sale Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: posProvider.isProcessing
                          ? null
                          : () async {
                              final completedSale = await posProvider.checkout(
                                userId: userId,
                                paymentMethod: paymentMethod,
                                paidAmount: paid,
                                cashierName: cashierName,
                              );

                              if (completedSale != null) {
                                await productProvider.loadData();
                                await salesProvider.loadSales();
                                await reportsProvider.loadDashboardMetrics();

                                if (context.mounted) {
                                  Navigator.of(ctx).pop();
                                  _showReceiptDialog(context, completedSale, settings);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: posProvider.isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Sale & Print Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentTypeChip(String type, String label, IconData icon, String current, Function(String) onSelect) {
    final isSelected = type == current;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen.withValues(alpha:0.25) : AppTheme.bgDarkCardHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryMint : AppTheme.textDarkSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, SaleModel sale, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 10),
              Text('Sale Completed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice: ${sale.invoiceNumber}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Total: ${Formatters.formatCurrency(sale.total, symbol: settings.currencySymbol)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Would you like to print or download the thermal receipt now?', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.textDarkSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Print 80mm Receipt'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ReceiptPdfGenerator.printReceipt(
                  sale,
                  storeName: settings.storeName,
                  storePhone: settings.storePhone,
                  storeAddress: settings.storeAddress,
                  currencySymbol: settings.currencySymbol,
                  receiptFooter: settings.receiptFooter,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
