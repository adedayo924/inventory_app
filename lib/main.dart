import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/database_factory.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/distributors_provider.dart';
import 'presentation/providers/expenses_provider.dart';
import 'presentation/providers/pos_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/purchases_provider.dart';
import 'presentation/providers/reports_provider.dart';
import 'presentation/providers/sales_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/auth/force_password_change_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database factory (FFI for Desktop/Mobile, IndexedDB for Web)
  await initializeDatabaseFactory();

  runApp(const JimsApp());
}

class JimsApp extends StatelessWidget {
  const JimsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => DistributorsProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'JIMS - Jeilo Inventory Management System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) {
                  return const LoginScreen();
                }
                if (auth.requiresPasswordChange) {
                  return const ForcePasswordChangeScreen();
                }
                return const MainNavigationScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
