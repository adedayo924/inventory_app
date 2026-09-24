import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/settings_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  void _showAddExpenseDialog() {
    final provider = Provider.of<ExpensesProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedType = 'Operating';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgDarkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_card_rounded, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Log Operating Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description (e.g. Generator Diesel, Cleaning) *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Amount (₦) *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: AppTheme.bgDarkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: ['Operating', 'Utilities & Power', 'Maintenance', 'Salaries', 'Supplies', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => selectedType = val ?? 'Operating'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Notes / Receipt info'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: () async {
                  final desc = descCtrl.text.trim();
                  final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                  if (desc.isEmpty || amt <= 0) return;

                  await provider.addExpense(
                    userId: auth.currentUser?.id ?? 1,
                    description: desc,
                    amount: amt,
                    type: selectedType,
                    note: noteCtrl.text.trim(),
                  );

                  if (mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save Expense'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpensesProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Operating Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Total: ${Formatters.formatCurrency(provider.totalExpenses, symbol: symbol)}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Log Expense'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: _showAddExpenseDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : provider.expenses.isEmpty
                      ? const Center(child: Text('No expense records logged.', style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgDarkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ListView.separated(
                            itemCount: provider.expenses.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                            itemBuilder: (context, index) {
                              final e = provider.expenses[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed.withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.dangerRed, size: 20),
                                ),
                                title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                subtitle: Text('${Formatters.formatDateTimeFromIso(e.createdAt)} • ${e.type}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(e.amount, symbol: symbol),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.textDarkSecondary, size: 18),
                                      onPressed: () => provider.deleteExpense(e.id),
                                    ),
                                  ],
                                ),
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
}
