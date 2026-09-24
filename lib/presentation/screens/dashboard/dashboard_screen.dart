import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final reports = Provider.of<ReportsProvider>(context, listen: false);
    final products = Provider.of<ProductProvider>(context, listen: false);
    final sales = Provider.of<SalesProvider>(context, listen: false);

    await reports.loadDashboardMetrics();
    await products.loadData();
    await sales.loadSales();
  }

  @override
  Widget build(BuildContext context) {
    final reports = Provider.of<ReportsProvider>(context);
    final products = Provider.of<ProductProvider>(context);
    final sales = Provider.of<SalesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final symbol = settings.currencySymbol;
    final m = reports.metrics;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28.0 : 16.0,
            vertical: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retail Operations Dashboard',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live supermarket KPI performance & inventory intelligence',
                        style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryMint),
                    tooltip: 'Refresh Metrics',
                    onPressed: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Critical Expiry / Low Stock Alert Banner
              if (products.totalExpiredCount > 0 || products.totalNearExpiryCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha:0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inventory Expiry Warning',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              '${products.totalExpiredCount} product(s) expired, ${products.totalNearExpiryCount} product(s) expiring within 30 days.',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Metric Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1100 ? 4 : (width > 650 ? 2 : 1);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: width > 650 ? 1.6 : 2.2,
                    children: [
                      _buildMetricCard(
                        title: 'Total Revenue',
                        value: Formatters.formatCurrency(m.totalSales, symbol: symbol),
                        subtitle: '${m.totalOrders} transactions recorded',
                        icon: Icons.payments_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      _buildMetricCard(
                        title: 'Gross Profit',
                        value: Formatters.formatCurrency(m.grossProfit, symbol: symbol),
                        subtitle: 'Net: ${Formatters.formatCurrency(m.netProfit, symbol: symbol)}',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.primaryMint,
                      ),
                      _buildMetricCard(
                        title: 'Stock Valuation',
                        value: Formatters.formatCurrency(m.inventoryValue, symbol: symbol),
                        subtitle: '${m.totalProducts} catalog products',
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.infoSky,
                      ),
                      _buildMetricCard(
                        title: 'Stock Alerts',
                        value: '${m.lowStockCount} Low',
                        subtitle: '${m.nearExpiryCount} near expiry date',
                        icon: Icons.notifications_active_rounded,
                        color: m.lowStockCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Sales Chart Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Revenue Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Latest Transactions',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryMint),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: m.totalSales > 0 ? (m.totalSales * 1.2) : 10000,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
                                  final index = val.toInt();
                                  if (index >= 0 && index < titles.length) {
                                    return Text(titles[index], style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _buildBarGroup(0, m.totalSales * 0.15),
                            _buildBarGroup(1, m.totalSales * 0.25),
                            _buildBarGroup(2, m.totalSales * 0.18),
                            _buildBarGroup(3, m.totalSales * 0.35),
                            _buildBarGroup(4, m.totalSales * 0.42),
                            _buildBarGroup(5, m.totalSales * 0.60),
                            _buildBarGroup(6, m.totalSales),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions Table Header
              const Text(
                'Recent Invoices & Transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Recent Sales List
              if (sales.sales.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDarkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: const Center(
                    child: Text('No sales records yet.', style: TextStyle(color: AppTheme.textDarkSecondary)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDarkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sales.sales.take(5).length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                    itemBuilder: (context, index) {
                      final s = sales.sales[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryGreen, size: 20),
                        ),
                        title: Text(
                          s.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${Formatters.formatDateTimeFromIso(s.createdAt)} • ${s.paymentMethod.toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                        ),
                        trailing: Text(
                          Formatters.formatCurrency(s.total, symbol: symbol),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textDarkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: x == 6 ? AppTheme.primaryGreen : AppTheme.primaryDarkGreen,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
