import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/barcode_scanner_dialog.dart';
import '../../../core/utils/csv_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() async {
    final scannedCode = await BarcodeScannerDialog.show(context);
    if (scannedCode != null && mounted) {
      _searchCtrl.text = scannedCode;
      Provider.of<ProductProvider>(context, listen: false).setSearchQuery(scannedCode);
    }
  }

  void _showAddEditDialog([ProductModel? product]) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final isEditing = product != null;

    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final costCtrl = TextEditingController(text: product != null ? product.costPrice.toString() : '');
    final sellCtrl = TextEditingController(text: product != null ? product.sellPrice.toString() : '');
    final qtyCtrl = TextEditingController(text: product != null ? product.quantity.toString() : '0');
    final alertCtrl = TextEditingController(text: product != null ? product.alertQuantity.toString() : '10');
    final expiryCtrl = TextEditingController(text: product?.expiryDate ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');

    int? selectedCategory = product?.categoryId ?? (provider.categories.isNotEmpty ? provider.categories.first.id : null);
    int? selectedBrand = product?.brandId ?? (provider.brands.isNotEmpty ? provider.brands.first.id : null);
    int? selectedUnit = product?.unitId ?? (provider.units.isNotEmpty ? provider.units.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgDarkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Product' : 'Add New Product',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Product Name *'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: skuCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'SKU Code *'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: barcodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Barcode',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
                                  onPressed: () async {
                                    final code = await BarcodeScannerDialog.show(context);
                                    if (code != null) {
                                      setDlgState(() => barcodeCtrl.text = code);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: selectedCategory,
                              dropdownColor: AppTheme.bgDarkCard,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (val) => setDlgState(() => selectedCategory = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: selectedBrand,
                              dropdownColor: AppTheme.bgDarkCard,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Brand'),
                              items: provider.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                              onChanged: (val) => setDlgState(() => selectedBrand = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Cost Price'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: sellCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Sell Price *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Stock Quantity'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: alertCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Alert Threshold'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expiryCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Expiry Date (YYYY-MM-DD)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 365)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDlgState(() {
                                  expiryCtrl.text = Formatters.formatDateOnly(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textDarkSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final sku = skuCtrl.text.trim();
                    if (name.isEmpty || sku.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name and SKU are required'), backgroundColor: AppTheme.dangerRed),
                      );
                      return;
                    }

                    final cost = double.tryParse(costCtrl.text) ?? 0.0;
                    final sell = double.tryParse(sellCtrl.text) ?? 0.0;
                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                    final alert = int.tryParse(alertCtrl.text) ?? 10;
                    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');

                    final data = {
                      'category_id': selectedCategory,
                      'brand_id': selectedBrand,
                      'unit_id': selectedUnit,
                      'name': name,
                      'slug': slug,
                      'sku': sku,
                      'barcode': barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                      'cost_price': cost,
                      'sell_price': sell,
                      'alert_quantity': alert,
                      'expiry_date': expiryCtrl.text.trim().isEmpty ? null : expiryCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    };

                    bool success;
                    if (isEditing) {
                      success = await provider.updateProduct(product.id, data, qty);
                    } else {
                      success = await provider.addProduct(data, qty);
                    }

                    if (success && context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Product updated' : 'Product added successfully'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
        child: Column(
          children: [
            // Action Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products by name, SKU or barcode...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textDarkSecondary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textDarkSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGreen),
                  tooltip: 'Scan Barcode',
                  onPressed: _openBarcodeScanner,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(isDesktop ? 'Add Product' : 'Add'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () => _showAddEditDialog(),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined, size: 18, color: AppTheme.primaryMint),
                    label: const Text('Import CSV', style: TextStyle(color: AppTheme.primaryMint)),
                    onPressed: () async {
                      final imported = await provider.importFromCsv();
                      if (imported && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Products imported from CSV!'), backgroundColor: AppTheme.successGreen),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 18, color: AppTheme.textDarkSecondary),
                    label: const Text('Export CSV', style: TextStyle(color: AppTheme.textDarkSecondary)),
                    onPressed: () => CsvHelper.exportProductsCsv(context, provider.products),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Products Table or List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : provider.products.isEmpty
                      ? const Center(child: Text('No products found', style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : isDesktop
                          ? _buildDesktopTable(provider, symbol)
                          : _buildMobileList(provider, symbol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(ProductProvider provider, String symbol) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.bgDarkCardHover),
            columns: const [
              DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('SKU / Barcode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Sell Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            ],
            rows: provider.products.map((p) {
              return DataRow(
                cells: [
                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  DataCell(Text('${p.sku}\n${p.barcode ?? "-"}', style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary))),
                  DataCell(Text(p.categoryName ?? 'General', style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(Formatters.formatCurrency(p.costPrice, symbol: symbol), style: const TextStyle(color: AppTheme.textDarkSecondary))),
                  DataCell(Text(Formatters.formatCurrency(p.sellPrice, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint))),
                  DataCell(Text('${p.quantity} ${p.unitName ?? "pcs"}', style: TextStyle(fontWeight: FontWeight.bold, color: p.isLowStock ? AppTheme.warningAmber : Colors.white))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.quantity <= 0
                            ? AppTheme.dangerRed.withValues(alpha:0.15)
                            : (p.isLowStock ? AppTheme.warningAmber.withValues(alpha:0.15) : AppTheme.successGreen.withValues(alpha:0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.quantity <= 0 ? 'Out of Stock' : (p.isLowStock ? 'Low Stock' : 'In Stock'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.quantity <= 0 ? AppTheme.dangerRed : (p.isLowStock ? AppTheme.warningAmber : AppTheme.successGreen),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryMint, size: 20),
                          tooltip: 'Edit Product',
                          onPressed: () => _showAddEditDialog(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                          tooltip: 'Delete Product',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.bgDarkCard,
                                title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
                                content: Text('Are you sure you want to deactivate "${p.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                                    onPressed: () => Navigator.of(c).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await provider.deleteProduct(p.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(ProductProvider provider, String symbol) {
    return ListView.separated(
      itemCount: provider.products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = provider.products[index];
        return Card(
          color: AppTheme.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderDark)),
          child: ListTile(
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text('SKU: ${p.sku} • Stock: ${p.quantity}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
            trailing: Text(
              Formatters.formatCurrency(p.sellPrice, symbol: symbol),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint),
            ),
            onTap: () => _showAddEditDialog(p),
          ),
        );
      },
    );
  }
}
