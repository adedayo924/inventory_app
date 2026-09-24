import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Formatters {
  static const String _isoPattern = 'yyyy-MM-dd HH:mm';

  static String formatCurrency(double amount, {String symbol = '₦'}) {
    final formatter = NumberFormat.currency(symbol: '$symbol ', decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat(_isoPattern).format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTimeFromIso(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso.length > 16 ? iso.substring(0, 16) : iso;
    return DateFormat(_isoPattern).format(parsed.toLocal());
  }

  static String generateInvoiceNumber({String prefix = 'INV'}) {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return '$prefix-$datePart-${_shortUuid().toUpperCase()}';
  }

  static String generatePurchaseInvoice() {
    return generateInvoiceNumber(prefix: 'PUR');
  }

  static String _shortUuid() => const Uuid().v4().replaceAll('-', '').substring(0, 8);
}
