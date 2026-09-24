import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void _showNewPurchaseDialog() {
    final purchasesProvider = Provider.of<PurchasesProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    int? selectedSupplier = purchasesProvider.suppliers.isNotEmpty ? purchasesProvider.suppliers.first.id : null;
    final List<Map<String, dynamic>> orderItems = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
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
                  Text('New Purchase / Stock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supplier selector
                      DropdownButtonFormField<int?>(
                        value: selectedSupplier,
                        dropdownColor: AppTheme.bgDarkCard,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Supplier'),
                        items: purchasesProvider.suppliers
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (val) => setDlgState(() => selectedSupplier = val),
                      ),
                      const SizedBox(height: 16),

                      const Text('Items to Replenish:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),

                      if (orderItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No items added yet. Click "+ Add Item" below.', style: TextStyle(color: AppTheme.textDarkSecondary)),
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
                                    child: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                  Text('${item['quantity']}x @ ${item['cost_price']} = ${item['subtotal']}',
                                      style: const TextStyle(color: AppTheme.primaryMint, fontSize: 12)),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppTheme.dangerRed, size: 18),
                                    onPressed: () {
                                      setDlgState(() => orderItems.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 12),

                      // Add Item Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 18),
                        label: const Text('Add Product to Order', style: TextStyle(color: AppTheme.primaryGreen)),
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
                          const Text('Total Purchase Cost:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(Formatters.formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryMint, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
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

                          if (success && context.mounted) {
                            await productProvider.loadData();
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Purchase received and inventory updated!'), backgroundColor: AppTheme.successGreen),
                            );
                          }
                        },
                  child: const Text('Receive Purchase'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPickProductDialog(ProductProvider productProvider, Function(dynamic, int, double) onAdd) {
    int? selectedId = productProvider.products.isNotEmpty ? productProvider.products.first.id : null;
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(text: productProvider.products.isNotEmpty ? productProvider.products.first.costPrice.toString() : '0');

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
                  value: selectedId,
                  dropdownColor: AppTheme.bgDarkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: productProvider.products
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    setPickState(() {
                      selectedId = val;
                      final p = productProvider.products.firstWhere((item) => item.id == val);
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: () {
                  if (selectedId != null) {
                    final prod = productProvider.products.firstWhere((p) => p.id == selectedId);
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

  @override
  Widget build(BuildContext context) {
    final purchasesProvider = Provider.of<PurchasesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchases & Stock In',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
            Expanded(
              child: purchasesProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : purchasesProvider.purchases.isEmpty
                      ? const Center(child: Text('No purchase records found.', style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ListView.separated(
                            itemCount: purchasesProvider.purchases.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                            itemBuilder: (context, index) {
                              final p = purchasesProvider.purchases[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoSky.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_shipping_outlined, color: AppTheme.infoSky, size: 22),
                                ),
                                title: Text(p.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                subtitle: Text(
                                  '${Formatters.formatDateTimeFromIso(p.createdAt)} • Supplier: ${p.supplierName ?? "General Wholesale"}',
                                  style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
                                ),
                                trailing: Text(
                                  Formatters.formatCurrency(p.total, symbol: symbol),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint, fontSize: 15),
                                ),
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
