import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).loadDashboardMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final m = reports.metrics;

    final marginPercent = m.totalSales > 0 ? (m.grossProfit / m.totalSales * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Intelligence & Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Comprehensive Profit & Loss (P&L) and stock intelligence', style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export P&L Report CSV'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    onPressed: () => CsvHelper.exportReportCsv(
                      context,
                      salesCount: m.totalOrders,
                      grossSales: m.totalSales,
                      expenses: m.totalExpenses,
                      netProfit: m.netProfit,
                      storeName: settings.storeName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // P&L Statement Card
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
                    const Text('Profit & Loss Statement (P&L)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildReportRow('Gross Sales Revenue', Formatters.formatCurrency(m.totalSales, symbol: symbol), isBold: true, color: Colors.white),
                    const SizedBox(height: 8),
                    _buildReportRow('Cost of Goods Sold (COGS)', '- ${Formatters.formatCurrency(m.totalCogs, symbol: symbol)}', color: AppTheme.textDarkSecondary),
                    const Divider(color: AppTheme.borderDark, height: 24),
                    _buildReportRow('Gross Profit', Formatters.formatCurrency(m.grossProfit, symbol: symbol), isBold: true, color: AppTheme.primaryMint, tag: '$marginPercent% Margin'),
                    const SizedBox(height: 8),
                    _buildReportRow('Operating Expenses', '- ${Formatters.formatCurrency(m.totalExpenses, symbol: symbol)}', color: AppTheme.dangerRed),
                    const Divider(color: AppTheme.borderDark, height: 24),
                    _buildReportRow('NET ESTIMATED PROFIT', Formatters.formatCurrency(m.netProfit, symbol: symbol), isBold: true, color: AppTheme.primaryGreen, isHighlight: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Inventory Valuation Card
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
                    const Text('Inventory Asset Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildReportRow('Total Active Products', '${m.totalProducts} items', color: Colors.white),
                    const SizedBox(height: 8),
                    _buildReportRow('Total Stock Cost Valuation', Formatters.formatCurrency(m.inventoryValue, symbol: symbol), color: AppTheme.infoSky, isBold: true),
                    const SizedBox(height: 8),
                    _buildReportRow('Low Stock Products Count', '${m.lowStockCount} items below alert threshold', color: m.lowStockCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen),
                    const SizedBox(height: 8),
                    _buildReportRow('Near Expiry Count (< 30 days)', '${m.nearExpiryCount} items', color: m.nearExpiryCount > 0 ? AppTheme.dangerRed : AppTheme.successGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? color, String? tag, bool isHighlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isHighlight ? 8 : 4, horizontal: isHighlight ? 12 : 0),
      decoration: isHighlight
          ? BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.3)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBold ? Colors.white : AppTheme.textDarkSecondary,
                  fontSize: isHighlight ? 15 : 13,
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primaryMint.withValues(alpha:0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryMint)),
                ),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.white,
              fontSize: isHighlight ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
