import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/theme/app_theme.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key});

  void _showSetBudgetDialog(BuildContext context, BudgetProvider budgetProvider, int userId) {
    final controller = TextEditingController(
      text: budgetProvider.monthlyBudget > 0
          ? (budgetProvider.monthlyBudget % 1 == 0
              ? budgetProvider.monthlyBudget.toInt().toString()
              : budgetProvider.monthlyBudget.toString())
          : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Target Budget Bulanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentukan batas maksimal pengeluaran bulananmu agar keuangan tetap terkendali.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target Anggaran (Rp)',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                await budgetProvider.setMonthlyBudget(userId, val);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final double monthlyExpense = ((transactionProvider.dashboardData['monthlyExpense'] as num?)?.toDouble() ?? 0.0);
    final double budget = budgetProvider.monthlyBudget;
    final double progress = budget > 0 ? (monthlyExpense / budget).clamp(0.0, 1.0) : 0.0;
    final double percentage = budget > 0 ? (monthlyExpense / budget) * 100 : 0.0;
    final double remaining = budget > 0 ? budget - monthlyExpense : 0.0;

    Color progressColor;
    Color badgeBg;
    String statusText;
    if (percentage >= 100) {
      progressColor = AppColors.expense;
      badgeBg = AppColors.expenseLight;
      statusText = 'Over budget! Rem pengeluaran!';
    } else if (percentage >= 80) {
      progressColor = AppColors.warning;
      badgeBg = AppColors.warningLight;
      statusText = 'Mendekati limit (${percentage.toStringAsFixed(0)}% terpakai)';
    } else {
      progressColor = AppColors.income;
      badgeBg = AppColors.incomeLight;
      statusText = 'Pengeluaran terkendali (${percentage.toStringAsFixed(0)}%)';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.savings_rounded, color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Budget Bulanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  if (authProvider.user != null) {
                    _showSetBudgetDialog(context, budgetProvider, authProvider.user!.id);
                  }
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: Text(
                  budget > 0 ? 'Atur' : 'Pasang Target',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (budget <= 0)
            InkWell(
              onTap: () {
                if (authProvider.user != null) {
                  _showSetBudgetDialog(context, budgetProvider, authProvider.user!.id);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_chart_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada target pengeluaran. Ketuk untuk pasang!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terpakai',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          currencyFormat.format(monthlyExpense),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dari ${currencyFormat.format(budget)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      remaining >= 0
                          ? 'Sisa: ${currencyFormat.format(remaining)}'
                          : 'Lebih: ${currencyFormat.format(-remaining)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
