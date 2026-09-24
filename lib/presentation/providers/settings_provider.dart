import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  String _storeName = 'Jeilo Supermarket & Retail Store';
  String _storePhone = '+234 800 123 4567';
  String _storeEmail = 'info@jeilo.com';
  String _storeAddress = 'Plot 10 Commercial Hub, Central City';
  String _currencySymbol = '₦';
  double _taxRate = 7.5;
  int _expiryAlertDays = 30;
  String _receiptFooter = 'Thank you for shopping with Jeilo! Quality guaranteed.';
  bool _isDarkMode = true;
  bool _isLoading = false;

  String get storeName => _storeName;
  String get storePhone => _storePhone;
  String get storeEmail => _storeEmail;
  String get storeAddress => _storeAddress;
  String get currencySymbol => _currencySymbol;
  double get taxRate => _taxRate;
  int get expiryAlertDays => _expiryAlertDays;
  String get receiptFooter => _receiptFooter;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = await DatabaseHelper.instance.getAllSettings();
      if (settings.containsKey('store_name')) _storeName = settings['store_name']!;
      if (settings.containsKey('store_phone')) _storePhone = settings['store_phone']!;
      if (settings.containsKey('store_email')) _storeEmail = settings['store_email']!;
      if (settings.containsKey('store_address')) _storeAddress = settings['store_address']!;
      if (settings.containsKey('currency_symbol')) _currencySymbol = settings['currency_symbol']!;
      if (settings.containsKey('tax_rate')) {
        _taxRate = double.tryParse(settings['tax_rate']!) ?? 7.5;
      }
      if (settings.containsKey('expiry_alert_days')) {
        _expiryAlertDays = int.tryParse(settings['expiry_alert_days']!) ?? 30;
      }
      if (settings.containsKey('receipt_footer')) _receiptFooter = settings['receipt_footer']!;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSetting(String key, String value) async {
    await DatabaseHelper.instance.setSetting(key, value);
    await loadSettings();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
