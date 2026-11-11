import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';

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
        title: const Text('Set Monthly Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your maximum monthly spending limit to stay financially on track.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Budget (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                await budgetProvider.setMonthlyBudget(userId, val);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
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
    String statusText;
    if (percentage >= 100) {
      progressColor = Colors.red.shade700;
      statusText = 'Budget exceeded! Watch out!';
    } else if (percentage >= 80) {
      progressColor = Colors.orange.shade700;
      statusText = 'Approaching limit (${percentage.toStringAsFixed(0)}% used)';
    } else {
      progressColor = Colors.green.shade600;
      statusText = 'On track (${percentage.toStringAsFixed(0)}% used)';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
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
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.savings_outlined, color: Colors.amber.shade800, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(budget > 0 ? 'Edit' : 'Set Budget'),
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No budget set for this month. Tap to set your target!',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
                    children: [
                      Text(
                        currencyFormat.format(monthlyExpense),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        'Target: ${currencyFormat.format(budget)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        remaining >= 0
                            ? 'Remaining: ${currencyFormat.format(remaining)}'
                            : 'Over: ${currencyFormat.format(-remaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
