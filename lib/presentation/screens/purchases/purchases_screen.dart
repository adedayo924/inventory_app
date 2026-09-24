import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/settings_provider.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // ── New Purchase Order Dialog ──────────────────────────────────────────
  void _showNewPurchaseDialog() {
    final purchasesProvider = Provider.of<PurchasesProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    int? selectedSupplier = purchasesProvider.suppliers.isNotEmpty
        ? purchasesProvider.suppliers.first.id
        : null;
    final List<Map<String, dynamic>> orderItems = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) {
          double total = 0.0;
          for (var item in orderItems) {
            total += (item['subtotal'] as num).toDouble();
          }

          return AlertDialog(
            backgroundColor: AppTheme.bgDarkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('New Purchase / Stock In',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: selectedSupplier,
                      dropdownColor: AppTheme.bgDarkCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: purchasesProvider.suppliers
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => setDlgState(() => selectedSupplier = val),
                    ),
                    const SizedBox(height: 16),
                    const Text('Items to Replenish:',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    if (orderItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No items added yet. Click "+ Add Item" below.',
                          style: TextStyle(color: AppTheme.textDarkSecondary),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          final item = orderItems[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDarkCardHover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(item['name'] as String,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  '${item['quantity']}x @ ${item['cost_price']} = ${item['subtotal']}',
                                  style: const TextStyle(
                                      color: AppTheme.primaryMint, fontSize: 12),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppTheme.dangerRed, size: 18),
                                  onPressed: () =>
                                      setDlgState(() => orderItems.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppTheme.primaryGreen, size: 18),
                      label: const Text('Add Product to Order',
                          style: TextStyle(color: AppTheme.primaryGreen)),
                      onPressed: () {
                        _showPickProductDialog(productProvider, (prod, qty, cost) {
                          setDlgState(() {
                            orderItems.add({
                              'product_id': prod.id,
                              'name': prod.name,
                              'quantity': qty,
                              'cost_price': cost,
                              'subtotal': qty * cost,
                            });
                          });
                        });
                      },
                    ),
                    const Divider(color: AppTheme.borderDark, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Purchase Cost:',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(
                          Formatters.formatCurrency(total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryMint,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: orderItems.isEmpty
                    ? null
                    : () async {
                        final success = await purchasesProvider.createPurchaseOrder(
                          supplierId: selectedSupplier,
                          userId: auth.currentUser?.id ?? 1,
                          items: orderItems,
                        );
                        if (!mounted) return;
                        await productProvider.loadData();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Purchase received and inventory updated!'
                                : 'Failed to record purchase.'),
                            backgroundColor:
                                success ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        );
                      },
                child: const Text('Receive Purchase'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Pick Product Sub-dialog ────────────────────────────────────────────
  void _showPickProductDialog(
      ProductProvider productProvider, Function(dynamic, int, double) onAdd) {
    int? selectedId =
        productProvider.products.isNotEmpty ? productProvider.products.first.id : null;
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(
      text: productProvider.products.isNotEmpty
          ? productProvider.products.first.costPrice.toString()
          : '0',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgDarkCard,
            title: const Text('Select Product', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedId,
                  dropdownColor: AppTheme.bgDarkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: productProvider.products
                      .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    setPickState(() {
                      selectedId = val;
                      final p = productProvider.products
                          .firstWhere((item) => item.id == val);
                      costCtrl.text = p.costPrice.toString();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Unit Cost'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: () {
                  if (selectedId != null) {
                    final prod =
                        productProvider.products.firstWhere((p) => p.id == selectedId);
                    final qty = int.tryParse(qtyCtrl.text) ?? 1;
                    final cost = double.tryParse(costCtrl.text) ?? prod.costPrice;
                    onAdd(prod, qty, cost);
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Purchase Detail Dialog ─────────────────────────────────────────────
  Future<void> _showPurchaseDetail(
      BuildContext context, dynamic purchase, SettingsProvider settings) async {
    final items =
        await DatabaseHelper.instance.getPurchaseItems(purchase.id as int);
    if (!mounted) return;
    final symbol = settings.currencySymbol;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                purchase.invoiceNumber as String,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textDarkSecondary),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.calendar_today_outlined,
                    Formatters.formatDateTimeFromIso(purchase.createdAt as String)),
                _infoRow(Icons.local_shipping_outlined,
                    (purchase.supplierName as String?) ?? 'General Wholesale',
                    label: 'Supplier'),
                const Divider(color: AppTheme.borderDark, height: 20),
                const Text('Items Received:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13)),
                const SizedBox(height: 8),
                ...items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkCardHover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['product_name'] as String? ?? 'Product',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${item['quantity']}x @ ${Formatters.formatCurrency((item['cost_price'] as num?)?.toDouble() ?? 0, symbol: symbol)}',
                            style: const TextStyle(
                                color: AppTheme.textDarkSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                const Divider(color: AppTheme.borderDark, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Cost:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14)),
                    Text(
                      Formatters.formatCurrency(purchase.total as double,
                          symbol: symbol),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryMint,
                          fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, {String? label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textDarkSecondary),
          const SizedBox(width: 6),
          if (label != null)
            Text('$label: ',
                style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchasesProvider = Provider.of<PurchasesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    final totalPurchased =
        purchasesProvider.purchases.fold(0.0, (s, p) => s + p.total);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Purchases & Stock In',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(
                      'Total purchased: ${Formatters.formatCurrency(totalPurchased, symbol: symbol)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryMint,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New Purchase Order'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: _showNewPurchaseDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── List ──
            Expanded(
              child: purchasesProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : purchasesProvider.purchases.isEmpty
                      ? const Center(
                          child: Text('No purchase records found.',
                              style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ListView.separated(
                            itemCount: purchasesProvider.purchases.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppTheme.borderDark),
                            itemBuilder: (context, index) {
                              final p = purchasesProvider.purchases[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoSky.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_shipping_outlined,
                                      color: AppTheme.infoSky, size: 22),
                                ),
                                title: Text(p.invoiceNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14)),
                                subtitle: Text(
                                  '${Formatters.formatDateTimeFromIso(p.createdAt)} • ${p.supplierName ?? "General Wholesale"}',
                                  style: const TextStyle(
                                      color: AppTheme.textDarkSecondary, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(p.total, symbol: symbol),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryMint,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.textDarkSecondary, size: 20),
                                  ],
                                ),
                                onTap: () => _showPurchaseDetail(context, p, settings),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
