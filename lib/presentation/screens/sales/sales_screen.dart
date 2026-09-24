import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_pdf_generator.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  void _showSaleDetails(BuildContext context, SaleModel sale, SettingsProvider settings) {
    final symbol = settings.currencySymbol;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoice: ${sale.invoiceNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textDarkSecondary), onPressed: () => Navigator.of(ctx).pop()),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${Formatters.formatDateTimeFromIso(sale.createdAt)}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                  Text('Cashier: ${sale.cashierName ?? "N/A"}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                  Text('Customer: ${sale.customerName ?? "Walk-in"}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                  Text('Payment Method: ${sale.paymentMethod.toUpperCase()}', style: const TextStyle(color: AppTheme.primaryMint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Divider(color: AppTheme.borderDark, height: 20),
                  const Text('Items Purchased:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        Text(Formatters.formatCurrency(item.subtotal, symbol: symbol), style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13)),
                      ],
                    ),
                  )),
                  const Divider(color: AppTheme.borderDark, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      Text(Formatters.formatCurrency(sale.total, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 17)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.textDarkSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Re-Print Receipt'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () async {
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

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales & Invoices History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18, color: AppTheme.primaryGreen),
                  label: const Text('Export CSV', style: TextStyle(color: AppTheme.primaryGreen)),
                  onPressed: () => CsvHelper.exportSalesCsv(context, salesProvider.sales),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: salesProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : salesProvider.sales.isEmpty
                      ? const Center(child: Text('No sales records yet.', style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ListView.separated(
                            itemCount: salesProvider.sales.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                            itemBuilder: (context, index) {
                              final sale = salesProvider.sales[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGreen, size: 22),
                                ),
                                title: Text(
                                  sale.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${Formatters.formatDateTimeFromIso(sale.createdAt)} • ${sale.customerName ?? "Walk-in"} • ${sale.paymentMethod.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(sale.total, symbol: symbol),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined, color: AppTheme.textDarkSecondary, size: 20),
                                      tooltip: 'Print Receipt',
                                      onPressed: () => ReceiptPdfGenerator.printReceipt(
                                        sale,
                                        storeName: settings.storeName,
                                        storePhone: settings.storePhone,
                                        storeAddress: settings.storeAddress,
                                        currencySymbol: settings.currencySymbol,
                                        receiptFooter: settings.receiptFooter,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showSaleDetails(context, sale, settings),
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
