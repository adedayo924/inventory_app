import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auxiliary_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/distributors_provider.dart';
import '../../providers/settings_provider.dart';

class DistributorsScreen extends StatefulWidget {
  const DistributorsScreen({super.key});

  @override
  State<DistributorsScreen> createState() => _DistributorsScreenState();
}

class _DistributorsScreenState extends State<DistributorsScreen> {
  void _showAddDistributorDialog() {
    final provider = Provider.of<DistributorsProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        title: const Text('Add Distributor Agent', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 8),
            TextField(controller: codeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Code (e.g. DIST-002)')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await provider.addDistributor({
                'name': nameCtrl.text.trim(),
                'code': codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
              });
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(DistributorModel dist) {
    final provider = Provider.of<DistributorsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final amountCtrl = TextEditingController(text: dist.balance > 0 ? dist.balance.toStringAsFixed(2) : '0');
    final refCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDarkCard,
        title: Text('Commission Payout: ${dist.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance: ${Formatters.formatCurrency(dist.balance)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMint)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Payout Amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: refCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Payment Reference / Bank Slip'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt <= 0) return;
              await provider.payCommission(
                distributorId: dist.id,
                amount: amt,
                reference: refCtrl.text.trim(),
                note: noteCtrl.text.trim(),
                userId: auth.currentUser?.id ?? 1,
              );
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Record Payout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distProvider = Provider.of<DistributorsProvider>(context);
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
                const Text('Distributors & Commissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Distributor'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: _showAddDistributorDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: distProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : distProvider.distributors.isEmpty
                      ? const Center(child: Text('No distributors found.', style: TextStyle(color: AppTheme.textDarkSecondary)))
                      : ListView.separated(
                          itemCount: distProvider.distributors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = distProvider.distributors[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.bgDarkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('Code: ${d.code ?? "N/A"} • Tel: ${d.phone ?? "N/A"}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Earned: ${Formatters.formatCurrency(d.totalEarned, symbol: symbol)}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
                                          Text('Paid: ${Formatters.formatCurrency(d.totalPaid, symbol: symbol)}', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
                                          Text(
                                            'Balance: ${Formatters.formatCurrency(d.balance, symbol: symbol)}',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: d.balance > 0 ? AppTheme.primaryMint : Colors.white, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                                        onPressed: () => _showPayoutDialog(d),
                                        child: const Text('Payout', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
