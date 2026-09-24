import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_pdf_generator.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final provider = Provider.of<SalesProvider>(context, listen: false);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: provider.fromDate != null && provider.toDate != null
          ? DateTimeRange(start: provider.fromDate!, end: provider.toDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryGreen,
            onPrimary: Colors.white,
            surface: AppTheme.bgDarkCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      provider.setDateRange(range.start, range.end);
    }
  }

  void _showSaleDetails(BuildContext context, SaleModel sale, SettingsProvider settings) {
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
                'Invoice: ${sale.invoiceNumber}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                _detailRow(Icons.calendar_today_outlined, Formatters.formatDateTimeFromIso(sale.createdAt)),
                _detailRow(Icons.person_outline, sale.cashierName ?? 'N/A', label: 'Cashier'),
                _detailRow(Icons.person_pin_outlined, sale.customerName ?? 'Walk-in', label: 'Customer'),
                _detailRow(
                  Icons.payment_rounded,
                  sale.paymentMethod.toUpperCase(),
                  valueColor: AppTheme.primaryMint,
                  label: 'Method',
                ),
                if ((sale.discount) > 0)
                  _detailRow(Icons.discount_outlined, Formatters.formatCurrency(sale.discount, symbol: symbol),
                      label: 'Discount', valueColor: AppTheme.warningAmber),
                const Divider(color: AppTheme.borderDark, height: 24),
                const Text('Items Purchased:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                const SizedBox(height: 8),
                ...sale.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkCardHover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(item.subtotal, symbol: symbol),
                            style: const TextStyle(
                                color: AppTheme.textDarkSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )),
                const Divider(color: AppTheme.borderDark, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    Text(
                      Formatters.formatCurrency(sale.total, symbol: symbol),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 18),
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
      ),
    );
  }

  Widget _detailRow(IconData icon, String value, {String? label, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textDarkSecondary),
          const SizedBox(width: 6),
          if (label != null) ...[
            Text('$label: ', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: label == null ? FontWeight.normal : FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final hasFilters = salesProvider.fromDate != null ||
        salesProvider.toDate != null ||
        salesProvider.searchQuery.isNotEmpty ||
        salesProvider.paymentFilter != 'All';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales & Invoices History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  children: [
                    if (hasFilters)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16, color: AppTheme.warningAmber),
                        label: const Text('Clear Filters', style: TextStyle(color: AppTheme.warningAmber, fontSize: 12)),
                        onPressed: () {
                          _searchCtrl.clear();
                          salesProvider.clearFilters();
                        },
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined, size: 18, color: AppTheme.primaryGreen),
                      label: const Text('Export CSV', style: TextStyle(color: AppTheme.primaryGreen)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryGreen)),
                      onPressed: () => CsvHelper.exportSalesCsv(context, salesProvider.sales),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Filters Bar ──
            if (isDesktop)
              _buildFiltersBarDesktop(salesProvider)
            else
              _buildFiltersBarMobile(salesProvider),

            const SizedBox(height: 12),

            // ── Summary Strip ──
            _buildSummaryStrip(salesProvider, symbol),

            const SizedBox(height: 12),

            // ── Sales List ──
            Expanded(
              child: salesProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : salesProvider.sales.isEmpty
                      ? _buildEmptyState(hasFilters)
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ListView.separated(
                            itemCount: salesProvider.sales.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppTheme.borderDark),
                            itemBuilder: (context, index) {
                              final sale = salesProvider.sales[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      color: AppTheme.primaryGreen, size: 22),
                                ),
                                title: Text(
                                  sale.invoiceNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${Formatters.formatDateTimeFromIso(sale.createdAt)} • ${sale.customerName ?? "Walk-in"} • ${sale.paymentMethod.toUpperCase()} • ${sale.items.length} item(s)',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textDarkSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(sale.total, symbol: symbol),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryMint,
                                          fontSize: 15),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined,
                                          color: AppTheme.textDarkSecondary, size: 20),
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

  Widget _buildFiltersBarDesktop(SalesProvider provider) {
    return Row(
      children: [
        // Search
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search invoice, customer, cashier…',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textDarkSecondary, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppTheme.textDarkSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Date range
        _buildDateChip(provider),
        const SizedBox(width: 10),
        // Payment filter
        _buildPaymentDropdown(provider),
      ],
    );
  }

  Widget _buildFiltersBarMobile(SalesProvider provider) {
    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white),
          onChanged: provider.setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search invoice or customer…',
            prefixIcon: Icon(Icons.search, color: AppTheme.textDarkSecondary, size: 20),
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDateChip(provider)),
            const SizedBox(width: 8),
            Expanded(child: _buildPaymentDropdown(provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip(SalesProvider provider) {
    final hasDate = provider.fromDate != null;
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.bgDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasDate ? AppTheme.primaryGreen.withValues(alpha: 0.5) : AppTheme.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded,
                size: 16, color: hasDate ? AppTheme.primaryGreen : AppTheme.textDarkSecondary),
            const SizedBox(width: 8),
            Text(
              hasDate
                  ? '${Formatters.formatDateOnly(provider.fromDate!)} – ${Formatters.formatDateOnly(provider.toDate!)}'
                  : 'Date Range',
              style: TextStyle(
                  color: hasDate ? Colors.white : AppTheme.textDarkSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown(SalesProvider provider) {
    const methods = ['All', 'Cash', 'Card', 'Mobile'];
    return DropdownButtonFormField<String>(
      value: provider.paymentFilter == 'All' ? 'All' : provider.paymentFilter,
      initialValue: provider.paymentFilter,
      dropdownColor: AppTheme.bgDarkCard,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: const InputDecoration(
        labelText: 'Payment',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: methods
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (val) => provider.setPaymentFilter(val ?? 'All'),
    );
  }

  Widget _buildSummaryStrip(SalesProvider provider, String symbol) {
    return Row(
      children: [
        _summaryCard('Transactions', '${provider.filteredCount}', Icons.receipt_long_outlined, AppTheme.infoSky),
        const SizedBox(width: 10),
        _summaryCard(
          'Total Revenue',
          Formatters.formatCurrency(provider.filteredTotal, symbol: symbol),
          Icons.payments_rounded,
          AppTheme.primaryGreen,
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off_rounded : Icons.receipt_long_outlined,
            size: 60,
            color: AppTheme.textDarkSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No sales match your filters.' : 'No sales records yet.',
            style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 15),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                Provider.of<SalesProvider>(context, listen: false).clearFilters();
              },
              child: const Text('Clear Filters', style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          ],
        ],
      ),
    );
  }
}
