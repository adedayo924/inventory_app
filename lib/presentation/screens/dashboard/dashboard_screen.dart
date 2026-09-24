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

    // Today's sales from weekly data
    final todayStr = Formatters.formatDateOnly(DateTime.now());
    final todayEntry = reports.weeklySales.where((e) => e.date == todayStr).toList();
    final todayRevenue = todayEntry.isNotEmpty ? todayEntry.first.total : 0.0;
    final todayOrders = todayEntry.isNotEmpty ? todayEntry.first.orders : 0;

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
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_greeting()}, ${settings.storeName}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live operations dashboard • ${_formattedNow()}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
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
              const SizedBox(height: 16),

              // ── Today's Snapshot Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryDarkGreen.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.today_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Performance",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatCurrency(todayRevenue, symbol: symbol),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Orders Today', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(
                          '$todayOrders',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Critical Alerts Banner ──
              if (products.totalExpiredCount > 0 || products.totalNearExpiryCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inventory Expiry Warning',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            Text(
                              '${products.totalExpiredCount} product(s) expired, ${products.totalNearExpiryCount} expiring within 30 days.',
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

              // ── KPI Metric Cards ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1100 ? 4 : (width > 650 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: width > 650 ? 1.65 : 2.4,
                    children: [
                      _buildMetricCard(
                        title: 'Total Revenue',
                        value: Formatters.formatCurrency(m.totalSales, symbol: symbol),
                        subtitle: '${m.totalOrders} transactions',
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
                        subtitle: '${m.totalProducts} catalog SKUs',
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.infoSky,
                      ),
                      _buildMetricCard(
                        title: 'Stock Alerts',
                        value: '${m.lowStockCount} Low',
                        subtitle: '${m.nearExpiryCount} near expiry',
                        icon: Icons.notifications_active_rounded,
                        color: m.lowStockCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── 7-Day Revenue Chart ──
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
                    const Text('7-Day Revenue Overview',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 170,
                      child: _buildChart(reports, todayStr),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Layout: chart + top products side-by-side on desktop ──
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRecentSales(sales, symbol, settings)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildTopProducts(reports, symbol)),
                  ],
                )
              else ...[
                _buildRecentSales(sales, symbol, settings),
                const SizedBox(height: 16),
                _buildTopProducts(reports, symbol),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(ReportsProvider reports, String todayStr) {
    final now = DateTime.now();
    final dates = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return Formatters.formatDateOnly(d);
    });
    final Map<String, double> map = {for (var e in reports.weeklySales) e.date: e.total};
    final values = dates.map((d) => map[d] ?? 0.0).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.25 : 1000,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              rod.toY.toStringAsFixed(0),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                final d = DateTime.tryParse(dates[idx]);
                if (d == null) return const SizedBox.shrink();
                final label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
                final isToday = dates[idx] == todayStr;
                return Text(label,
                    style: TextStyle(
                      color: isToday ? AppTheme.primaryGreen : AppTheme.textDarkSecondary,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.borderDark, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final isToday = dates[i] == todayStr;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: isToday ? AppTheme.primaryGreen : AppTheme.primaryDarkGreen,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecentSales(SalesProvider sales, String symbol, SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        if (sales.allSales.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark)),
            child: const Center(
              child: Text('No sales records yet.',
                  style: TextStyle(color: AppTheme.textDarkSecondary)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
                color: AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.allSales.take(6).length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
              itemBuilder: (context, index) {
                final s = sales.allSales[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_rounded,
                        color: AppTheme.primaryGreen, size: 20),
                  ),
                  title: Text(s.invoiceNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  subtitle: Text(
                    '${Formatters.formatDateTimeFromIso(s.createdAt)} • ${s.paymentMethod.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary),
                  ),
                  trailing: Text(
                    Formatters.formatCurrency(s.total, symbol: symbol),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.primaryMint, fontSize: 14),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTopProducts(ReportsProvider reports, String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Sellers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: AppTheme.bgDarkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark)),
          child: reports.topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No sales data yet.',
                        style: TextStyle(color: AppTheme.textDarkSecondary)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.topProducts.take(5).length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderDark),
                  itemBuilder: (context, index) {
                    final p = reports.topProducts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: index < 3
                                ? AppTheme.primaryGreen
                                : AppTheme.textDarkSecondary,
                          ),
                        ),
                      ),
                      title: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text('${p.totalQty} units sold',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textDarkSecondary)),
                      trailing: Text(
                        Formatters.formatCurrency(p.totalRevenue, symbol: symbol),
                        style: const TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
      ],
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDarkSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textDarkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formattedNow() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
