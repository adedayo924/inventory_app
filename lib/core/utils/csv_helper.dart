import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart';
import 'csv_io_stub.dart'
    if (dart.library.io) 'csv_io_io.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';

class CsvHelper {
  // --- Export Products to CSV ---
  static Future<String?> exportProductsCsv(BuildContext context, List<ProductModel> products) async {
    final rows = <List<dynamic>>[
      [
        'id',
        'name',
        'sku',
        'barcode',
        'category',
        'brand',
        'unit',
        'cost_price',
        'sell_price',
        'quantity',
        'alert_quantity',
        'commission_rate',
        'expiry_date',
        'description',
      ],
      ...products.map((p) => [
            p.id,
            p.name,
            p.sku,
            p.barcode ?? '',
            p.categoryName ?? '',
            p.brandName ?? '',
            p.unitName ?? '',
            p.costPrice,
            p.sellPrice,
            p.quantity,
            p.alertQuantity,
            p.commissionRate,
            p.expiryDate ?? '',
            p.description ?? '',
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    return _saveTextFile(context, csvString, 'jims_products_$timestamp.csv');
  }

  // --- Export Sales History to CSV ---
  static Future<String?> exportSalesCsv(BuildContext context, List<SaleModel> sales) async {
    final rows = <List<dynamic>>[
      [
        'invoice_number',
        'date',
        'cashier',
        'customer',
        'distributor',
        'payment_method',
        'subtotal',
        'tax',
        'total',
        'paid',
        'change',
        'status',
      ],
      ...sales.map((s) => [
            s.invoiceNumber,
            s.createdAt,
            s.cashierName ?? 'N/A',
            s.customerName ?? 'Walk-in',
            s.distributorName ?? 'Direct',
            s.paymentMethod,
            s.subtotal,
            s.taxAmount,
            s.total,
            s.paid,
            s.change,
            s.status,
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    return _saveTextFile(context, csvString, 'jims_sales_$timestamp.csv');
  }

  // --- Export Report CSV ---
  static Future<String?> exportReportCsv(
    BuildContext context, {
    DateTime? from,
    DateTime? to,
    required int salesCount,
    required double grossSales,
    required double expenses,
    required double netProfit,
    String storeName = 'Jeilo Supermarket',
  }) {
    final generated = DateTime.now().toIso8601String().replaceFirst('T', ' ').substring(0, 19);
    final period = from != null && to != null ? '${_fmtDate(from)} to ${_fmtDate(to)}' : 'All time';

    final rows = <List<dynamic>>[
      ['$storeName - Sales & Financial Report (JIMS)'],
      ['Period', period],
      ['Generated', generated],
      <dynamic>[],
      ['SUMMARY METRICS'],
      ['Metric', 'Value'],
      ['Sales Transactions', salesCount],
      ['Gross Sales Revenue', grossSales],
      ['Total Expenses', expenses],
      ['Net Profit Estimate', netProfit],
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final periodSlug = from != null && to != null ? '${_fmtDate(from)}_${_fmtDate(to)}' : 'summary';
    return _saveTextFile(context, csvString, 'jims_report_$periodSlug.csv');
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<String?> _saveTextFile(BuildContext context, String csvString, String fileName) async {
    if (kIsWeb) {
      saveTextFileForWeb(csvString, fileName);
      return fileName;
    }
    return saveTextFileToDisk(csvString, fileName);
  }

  // --- Pick and Parse CSV File ---
  static Future<({List<Map<String, dynamic>> products, List<String> errors})?> pickAndParseCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final bytes = result.files.first.bytes;
      String csvContent;

      if (bytes != null) {
        csvContent = utf8.decode(bytes);
      } else if (result.files.first.path != null) {
        csvContent = await readTextFileFromDisk(result.files.first.path!);
      } else {
        return null;
      }

      return parseProductCsv(csvContent);
    } catch (e) {
      debugPrint('CSV pick error: $e');
      return null;
    }
  }

  static ({List<Map<String, dynamic>> products, List<String> errors}) parseProductCsv(String csvString) {
    final List<Map<String, dynamic>> products = [];
    final List<String> errors = [];

    List<List<dynamic>> rows;
    try {
      final normalized = csvString.replaceFirst('\uFEFF', '');
      rows = const CsvToListConverter().convert(normalized);
    } catch (e) {
      errors.add('Failed to parse CSV file: $e');
      return (products: products, errors: errors);
    }

    if (rows.isEmpty) {
      errors.add('CSV file is empty.');
      return (products: products, errors: errors);
    }

    final headerRow = rows.first
        .map((h) => h.toString().trim().toLowerCase().replaceAll('\uFEFF', '').replaceAll(' ', '_'))
        .toList();
    final nameIdx = headerRow.indexOf('name');
    final skuIdx = headerRow.indexOf('sku');

    if (nameIdx < 0 || skuIdx < 0) {
      errors.add('CSV is missing required columns: "name" and/or "sku".');
      return (products: products, errors: errors);
    }

    int colIdx(String col) => headerRow.indexOf(col);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) continue;

      final name = _cell(row, nameIdx);
      final sku = _cell(row, skuIdx);

      if (name.isEmpty) {
        errors.add('Row ${i + 1}: Missing required field "name" - skipped.');
        continue;
      }
      if (sku.isEmpty) {
        errors.add('Row ${i + 1}: Missing required field "sku" for "$name" - skipped.');
        continue;
      }

      final costStr = _cell(row, colIdx('cost_price'));
      final sellStr = _cell(row, colIdx('sell_price'));
      final costPrice = double.tryParse(costStr) ?? 0.0;
      final sellPrice = double.tryParse(sellStr) ?? 0.0;

      final expiryRaw = _cell(row, colIdx('expiry_date'));
      String? expiryDate;
      if (expiryRaw.isNotEmpty) {
        try {
          DateTime.parse(expiryRaw);
          expiryDate = expiryRaw;
        } catch (_) {
          errors.add('Row ${i + 1}: "$name" has invalid expiry_date "$expiryRaw".');
        }
      }

      products.add({
        'name': name,
        'sku': sku,
        'barcode': _cellOrNull(row, colIdx('barcode')),
        'cost_price': costPrice,
        'sell_price': sellPrice,
        'quantity': int.tryParse(_cell(row, colIdx('quantity'))) ?? 0,
        'alert_quantity': int.tryParse(_cell(row, colIdx('alert_quantity'))) ?? 10,
        'commission_rate': double.tryParse(_cell(row, colIdx('commission_rate'))) ?? 0.0,
        'expiry_date': expiryDate,
        'description': _cellOrNull(row, colIdx('description')),
      });
    }

    return (products: products, errors: errors);
  }

  static String _cell(List<dynamic> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx]?.toString().trim() ?? '';
  }

  static String? _cellOrNull(List<dynamic> row, int idx) {
    final v = _cell(row, idx);
    return v.isEmpty ? null : v;
  }
}
