import 'package:fl_chart/fl_chart.dart';
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

  Future<void> _pickCustomRange(ReportsProvider reports) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
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
      reports.setPeriod(
        ReportPeriod.custom,
        from: range.start,
        to: range.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final m = reports.metrics; // all-time
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final marginPercent = reports.periodSales > 0
        ? (reports.periodGrossProfit / reports.periodSales * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: reports.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: reports.loadDashboardMetrics,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 24.0 : 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Business Intelligence & Reports',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 2),
                            Text('Profit & Loss, trends, and stock intelligence',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.textDarkSecondary)),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          label: const Text('Export P&L CSV'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          onPressed: () => CsvHelper.exportReportCsv(
                            context,
                            salesCount: reports.periodOrders,
                            grossSales: reports.periodSales,
                            expenses: reports.periodExpenses,
                            netProfit: reports.periodNetProfit,
                            storeName: settings.storeName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Period Filter Chips ──
                    _buildPeriodChips(reports),
                    const SizedBox(height: 20),

                    // ── Revenue Chart ──
                    _buildRevenueChart(reports, symbol),
                    const SizedBox(height: 20),

                    // ── Period P&L Card ──
                    _buildPLCard(reports, symbol, marginPercent),
                    const SizedBox(height: 20),

                    // ── Desktop: two-column layout for Inventory + Top Products ──
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInventoryCard(m, symbol)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTopProductsCard(reports, symbol)),
                        ],
                      )
                    else ...[
                      _buildInventoryCard(m, symbol),
                      const SizedBox(height: 16),
                      _buildTopProductsCard(reports, symbol),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ── Period Filter Chips ──────────────────────────────────────────────────
  Widget _buildPeriodChips(ReportsProvider reports) {
    final periods = [
      ReportPeriod.today,
      ReportPeriod.thisWeek,
      ReportPeriod.thisMonth,
      ReportPeriod.last30Days,
      ReportPeriod.allTime,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...periods.map((p) {
            final selected = reports.period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => reports.setPeriod(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryGreen
                        : AppTheme.bgDarkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AppTheme.primaryGreen
                            : AppTheme.borderDark),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : AppTheme.textDarkSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom range
          GestureDetector(
            onTap: () => _pickCustomRange(reports),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: reports.period == ReportPeriod.custom
                    ? AppTheme.purpleAccent
                    : AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: reports.period == ReportPeriod.custom
                        ? AppTheme.purpleAccent
                        : AppTheme.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    reports.period == ReportPeriod.custom &&
                            reports.customFrom != null
                        ? '${Formatters.formatDateOnly(reports.customFrom!)} – ${Formatters.formatDateOnly(reports.customTo!)}'
                        : 'Custom Range',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Revenue Line/Bar Chart ───────────────────────────────────────────────
  Widget _buildRevenueChart(ReportsProvider reports, String symbol) {
    final data = reports.weeklySales;
    // Build a list of last-7-day dates to fill in gaps
    final now = DateTime.now();
    final dates = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return Formatters.formatDateOnly(d);
    });

    final Map<String, double> dailyMap = {for (var e in data) e.date: e.total};
    final List<double> values = dates.map((d) => dailyMap[d] ?? 0).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    return Container(
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
              const Text('7-Day Revenue Trend',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last 7 Days',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryMint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.25 : 1000,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${symbol} ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                        final d = DateTime.tryParse(dates[idx]);
                        if (d == null) return const SizedBox.shrink();
                        final label = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
                        final isToday = dates[idx] == Formatters.formatDateOnly(now);
                        return Text(
                          label,
                          style: TextStyle(
                            color: isToday ? AppTheme.primaryGreen : AppTheme.textDarkSecondary,
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
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
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.borderDark,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isToday = dates[i] == Formatters.formatDateOnly(now);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: isToday ? AppTheme.primaryGreen : AppTheme.primaryDarkGreen,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Period P&L Statement ─────────────────────────────────────────────────
  Widget _buildPLCard(ReportsProvider reports, String symbol, String marginPercent) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(
                'P&L Statement — ${reports.period.label}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.infoSky.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${reports.periodOrders} orders',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.infoSky),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _reportRow('Gross Sales Revenue',
              Formatters.formatCurrency(reports.periodSales, symbol: symbol),
              isBold: true, color: Colors.white),
          const SizedBox(height: 6),
          _reportRow('Cost of Goods Sold (COGS)',
              '- ${Formatters.formatCurrency(reports.periodCogs, symbol: symbol)}',
              color: AppTheme.textDarkSecondary),
          const Divider(color: AppTheme.borderDark, height: 20),
          _reportRow('Gross Profit',
              Formatters.formatCurrency(reports.periodGrossProfit, symbol: symbol),
              isBold: true, color: AppTheme.primaryMint, tag: '$marginPercent% Margin'),
          const SizedBox(height: 6),
          _reportRow('Operating Expenses',
              '- ${Formatters.formatCurrency(reports.periodExpenses, symbol: symbol)}',
              color: AppTheme.dangerRed),
          const Divider(color: AppTheme.borderDark, height: 20),
          _reportRow('NET ESTIMATED PROFIT',
              Formatters.formatCurrency(reports.periodNetProfit, symbol: symbol),
              isBold: true,
              color: reports.periodNetProfit >= 0 ? AppTheme.primaryGreen : AppTheme.dangerRed,
              isHighlight: true),
        ],
      ),
    );
  }

  // ── Inventory Card ───────────────────────────────────────────────────────
  Widget _buildInventoryCard(dynamic m, String symbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Asset Summary',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _reportRow('Total Active Products', '${m.totalProducts} items',
              color: Colors.white),
          const SizedBox(height: 6),
          _reportRow('Stock Cost Valuation',
              Formatters.formatCurrency(m.inventoryValue, symbol: symbol),
              color: AppTheme.infoSky, isBold: true),
          const SizedBox(height: 6),
          _reportRow('Low Stock Alerts', '${m.lowStockCount} items',
              color: m.lowStockCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen),
          const SizedBox(height: 6),
          _reportRow('Near Expiry (< 30 days)', '${m.nearExpiryCount} items',
              color: m.nearExpiryCount > 0 ? AppTheme.dangerRed : AppTheme.successGreen),
        ],
      ),
    );
  }

  // ── Top Products Table ───────────────────────────────────────────────────
  Widget _buildTopProductsCard(ReportsProvider reports, String symbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 10 Best-Selling Products',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (reports.topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No sales data yet.',
                    style: TextStyle(color: AppTheme.textDarkSecondary)),
              ),
            )
          else ...[
            // Header row
            const Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text('Product',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textDarkSecondary,
                            fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                SizedBox(
                    width: 50,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textDarkSecondary,
                            fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                SizedBox(
                    width: 90,
                    child: Text('Revenue',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textDarkSecondary,
                            fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(color: AppTheme.borderDark, height: 12),
            ...reports.topProducts.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final maxQty = reports.topProducts.first.totalQty;
              final fraction = maxQty > 0 ? p.totalQty / maxQty : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: i < 3 ? AppTheme.primaryGreen : AppTheme.textDarkSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${p.totalQty}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.primaryMint,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            Formatters.formatCurrency(p.totalRevenue, symbol: symbol),
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: AppTheme.borderDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        i == 0 ? AppTheme.primaryGreen : AppTheme.primaryDarkGreen,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Shared row widget ───────────────────────────────────────────────────
  Widget _reportRow(String label, String value,
      {bool isBold = false, Color? color, String? tag, bool isHighlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isHighlight ? 8 : 4, horizontal: isHighlight ? 12 : 0),
      decoration: isHighlight
          ? BoxDecoration(
              color: (color ?? AppTheme.primaryGreen).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (color ?? AppTheme.primaryGreen).withValues(alpha: 0.3)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: isBold ? Colors.white : AppTheme.textDarkSecondary,
                    fontSize: isHighlight ? 14 : 13,
                  )),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryMint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(tag,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMint)),
                ),
              ],
            ],
          ),
          Text(value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.white,
                fontSize: isHighlight ? 16 : 14,
              )),
        ],
      ),
    );
  }
}
