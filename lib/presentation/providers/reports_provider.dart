import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/auxiliary_models.dart';

enum ReportPeriod { today, thisWeek, thisMonth, last30Days, allTime, custom }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.last30Days:
        return 'Last 30 Days';
      case ReportPeriod.allTime:
        return 'All Time';
      case ReportPeriod.custom:
        return 'Custom Range';
    }
  }
}

class TopProductEntry {
  final String name;
  final String sku;
  final int totalQty;
  final double totalRevenue;

  TopProductEntry({
    required this.name,
    required this.sku,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory TopProductEntry.fromMap(Map<String, dynamic> m) {
    return TopProductEntry(
      name: m['name'] as String? ?? '',
      sku: m['sku'] as String? ?? '',
      totalQty: (m['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (m['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeeklySalesEntry {
  final String date; // 'YYYY-MM-DD'
  final double total;
  final int orders;

  WeeklySalesEntry({required this.date, required this.total, required this.orders});

  factory WeeklySalesEntry.fromMap(Map<String, dynamic> m) {
    return WeeklySalesEntry(
      date: m['date'] as String? ?? '',
      total: (m['total'] as num?)?.toDouble() ?? 0.0,
      orders: (m['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportsProvider extends ChangeNotifier {
  DashboardMetrics _metrics = DashboardMetrics();
  bool _isLoading = false;
  String? _errorMessage;

  // Period
  ReportPeriod _period = ReportPeriod.allTime;
  DateTime? _customFrom;
  DateTime? _customTo;

  // Chart data
  List<WeeklySalesEntry> _weeklySales = [];
  List<TopProductEntry> _topProducts = [];

  // Period-specific P&L
  double _periodSales = 0;
  int _periodOrders = 0;
  double _periodCogs = 0;
  double _periodExpenses = 0;
  double _periodGrossProfit = 0;
  double _periodNetProfit = 0;

  // Getters
  DashboardMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReportPeriod get period => _period;
  DateTime? get customFrom => _customFrom;
  DateTime? get customTo => _customTo;
  List<WeeklySalesEntry> get weeklySales => _weeklySales;
  List<TopProductEntry> get topProducts => _topProducts;
  double get periodSales => _periodSales;
  int get periodOrders => _periodOrders;
  double get periodCogs => _periodCogs;
  double get periodExpenses => _periodExpenses;
  double get periodGrossProfit => _periodGrossProfit;
  double get periodNetProfit => _periodNetProfit;

  ReportsProvider() {
    loadDashboardMetrics();
  }

  void setPeriod(ReportPeriod p, {DateTime? from, DateTime? to}) {
    _period = p;
    if (p == ReportPeriod.custom) {
      _customFrom = from;
      _customTo = to;
    }
    loadDashboardMetrics();
  }

  String? _fromDate() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return _fmt(DateTime(now.year, now.month, now.day));
      case ReportPeriod.thisWeek:
        final weekday = now.weekday;
        return _fmt(now.subtract(Duration(days: weekday - 1)));
      case ReportPeriod.thisMonth:
        return _fmt(DateTime(now.year, now.month, 1));
      case ReportPeriod.last30Days:
        return _fmt(now.subtract(const Duration(days: 29)));
      case ReportPeriod.allTime:
        return null;
      case ReportPeriod.custom:
        return _customFrom != null ? _fmt(_customFrom!) : null;
    }
  }

  String? _toDate() {
    if (_period == ReportPeriod.custom && _customTo != null) {
      return _fmt(_customTo!);
    }
    return null;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadDashboardMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // All-time dashboard metrics (for the main KPI cards)
      final map = await DatabaseHelper.instance.getDashboardMetrics();
      _metrics = DashboardMetrics.fromMap(map);

      // Period-scoped P&L
      final periodMap = await DatabaseHelper.instance.getDashboardMetricsForPeriod(
        from: _fromDate(),
        to: _toDate(),
      );
      _periodSales = (periodMap['total_sales'] as num?)?.toDouble() ?? 0.0;
      _periodOrders = (periodMap['total_orders'] as num?)?.toInt() ?? 0;
      _periodCogs = (periodMap['total_cogs'] as num?)?.toDouble() ?? 0.0;
      _periodExpenses = (periodMap['total_expenses'] as num?)?.toDouble() ?? 0.0;
      _periodGrossProfit = (periodMap['gross_profit'] as num?)?.toDouble() ?? 0.0;
      _periodNetProfit = (periodMap['net_profit'] as num?)?.toDouble() ?? 0.0;

      // Chart data — always 7 days
      final weeklyRaw = await DatabaseHelper.instance.getWeeklySales(days: 7);
      _weeklySales = weeklyRaw.map(WeeklySalesEntry.fromMap).toList();

      // Top products
      final topRaw = await DatabaseHelper.instance.getTopSellingProducts(limit: 10);
      _topProducts = topRaw.map(TopProductEntry.fromMap).toList();
    } catch (e) {
      _errorMessage = 'Failed to load metrics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
