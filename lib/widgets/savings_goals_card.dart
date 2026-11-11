import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/models/savings_goal_model.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/savings_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:kos_finance_app/widgets/animated_popup.dart';

class SavingsGoalsCard extends StatelessWidget {
  const SavingsGoalsCard({super.key});

  void _showAddEditGoalDialog(
    BuildContext context, {
    SavingsGoal? goal,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final isEdit = goal != null;
    final titleController = TextEditingController(text: goal?.title ?? '');
    final targetController = TextEditingController(
      text: goal != null
          ? (goal.targetAmount % 1 == 0 ? goal.targetAmount.toInt().toString() : goal.targetAmount.toString())
          : '',
    );
    final noteController = TextEditingController(text: goal?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showAnimatedPopup(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.savings_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              isEdit ? 'Edit Celengan' : 'Buat Celengan Impian',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama Target (e.g. DP Kos, Pulang Kampung)',
                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama target wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Nominal (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Target nominal wajib diisi';
                  if (double.tryParse(val.replaceAll(',', '').trim()) == null) {
                    return 'Nominal tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Alasan Menabung',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final target = double.parse(targetController.text.replaceAll(',', '').trim());
                final title = titleController.text.trim();
                final note = noteController.text.trim();

                if (isEdit) {
                  await savingsProvider.updateGoal(
                    authProvider.user!.id,
                    goal.copyWith(
                      title: title,
                      targetAmount: target,
                      note: note,
                    ),
                  );
                } else {
                  final newGoal = SavingsGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    targetAmount: target,
                    currentAmount: 0.0,
                    note: note,
                  );
                  await savingsProvider.addGoal(authProvider.user!.id, newGoal);
                }

                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Mulai Celengan'),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(
    BuildContext context,
    SavingsGoal goal,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final amountController = TextEditingController();
    bool recordAsExpense = true;
    final formKey = GlobalKey<FormState>();

    showAnimatedPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.income, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nabung: ${goal.title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan nominal uang yang ingin kamu masukkan ke dalam celengan ini:',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Tabungan (Rp)',
                    prefixText: 'Rp ',
                  ),
                  validator: (val) {
                    final num = double.tryParse((val ?? '').replaceAll(',', '').trim());
                    if (num == null || num <= 0) return 'Masukkan nominal yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setModalState(() => recordAsExpense = !recordAsExpense),
                  child: Row(
                    children: [
                      Checkbox(
                        value: recordAsExpense,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setModalState(() => recordAsExpense = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Catat juga sebagai pengeluaran agar saldo kas utama berkurang',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text.replaceAll(',', '').trim());
                  await savingsProvider.deposit(authProvider.user!.id, goal.id, amount);

                  if (recordAsExpense) {
                    final tx = Transaction(
                      userId: authProvider.user!.id,
                      title: 'Nabung: ${goal.title}',
                      amount: amount,
                      date: DateTime.now(),
                      type: TransactionType.expense,
                      categoryId: 1,
                      note: 'Setor celengan impian',
                    );
                    await transactionProvider.addTransaction(tx, authProvider.user!.token);
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.income,
                        content: Text('Berhasil menabung Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)} ke celengan!'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              child: const Text('Setor Tabungan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    SavingsGoal goal,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final amountController = TextEditingController();
    bool recordAsIncome = true;
    final formKey = GlobalKey<FormState>();

    showAnimatedPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.expense, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tarik: ${goal.title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo celengan saat ini: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(goal.currentAmount)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Penarikan (Rp)',
                    prefixText: 'Rp ',
                  ),
                  validator: (val) {
                    final num = double.tryParse((val ?? '').replaceAll(',', '').trim());
                    if (num == null || num <= 0) return 'Masukkan nominal yang valid';
                    if (num > goal.currentAmount) return 'Nominal melebihi saldo celengan';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setModalState(() => recordAsIncome = !recordAsIncome),
                  child: Row(
                    children: [
                      Checkbox(
                        value: recordAsIncome,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setModalState(() => recordAsIncome = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Catat sebagai pemasukan agar saldo kas utama bertambah',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text.replaceAll(',', '').trim());
                  await savingsProvider.withdraw(authProvider.user!.id, goal.id, amount);

                  if (recordAsIncome) {
                    final tx = Transaction(
                      userId: authProvider.user!.id,
                      title: 'Cairkan Celengan: ${goal.title}',
                      amount: amount,
                      date: DateTime.now(),
                      type: TransactionType.income,
                      categoryId: 1,
                      note: 'Penarikan celengan impian',
                    );
                    await transactionProvider.addTransaction(tx, authProvider.user!.token);
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        content: Text('Berhasil mencairkan Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)} dari celengan!'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              child: const Text('Tarik Dana'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final goals = savingsProvider.goals;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.savings_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Celengan Kos Impian',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddEditGoalDialog(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (goals.isEmpty)
            InkWell(
              onTap: () => _showAddEditGoalDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada celengan. Ketuk untuk pasang target menabung!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Overall summary banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tabungan Terkumpul',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(savingsProvider.totalSaved),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(savingsProvider.overallProgress * 100).toInt()}% Target',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Individual Goals List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goal.isAchieved ? AppColors.income.withValues(alpha: 0.4) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (goal.isAchieved)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.income),
                                  ),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(goal.currentAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${currency.format(goal.targetAmount)} (${goal.percentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goal.isAchieved ? AppColors.income : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit',
                                onPressed: () => _showAddEditGoalDialog(context, goal: goal),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Hapus',
                                onPressed: () async {
                                  if (authProvider.user != null) {
                                    await savingsProvider.deleteGoal(authProvider.user!.id, goal.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (goal.currentAmount > 0)
                                TextButton(
                                  onPressed: () => _showWithdrawDialog(context, goal),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    foregroundColor: AppColors.expense,
                                  ),
                                  child: const Text('Tarik', style: TextStyle(fontSize: 12)),
                                ),
                              FilledButton.tonal(
                                onPressed: () => _showDepositDialog(context, goal),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 14),
                                    SizedBox(width: 2),
                                    Text('Nabung', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
