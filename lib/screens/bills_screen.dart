import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/models/bill_model.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:kos_finance_app/widgets/animated_popup.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int _filterIndex = 0; // 0: All, 1: Unpaid, 2: Paid

  void _showAddEditBillDialog({BillReminder? bill}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final isEdit = bill != null;
    final titleController = TextEditingController(text: bill?.title ?? '');
    final amountController = TextEditingController(
      text: bill != null
          ? (bill.amount % 1 == 0 ? bill.amount.toInt().toString() : bill.amount.toString())
          : '',
    );
    final dueDayController = TextEditingController(
      text: bill != null ? bill.dueDay.toString() : '5',
    );
    final noteController = TextEditingController(text: bill?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Tagihan' : 'Tambah Tagihan Baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: titleController,
                hintText: 'Nama Tagihan (e.g. Kamar Kos, Token Listrik)',
                prefixIcon: Icons.edit_note_rounded,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Masukkan nama tagihan' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: amountController,
                hintText: 'Nominal Tagihan (Rp)',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Masukkan nominal';
                  if (double.tryParse(val.replaceAll(',', '').trim()) == null) {
                    return 'Nominal tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: dueDayController,
                hintText: 'Tanggal Jatuh Tempo Tiap Bulan (1 - 31)',
                prefixIcon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  final day = int.tryParse(val?.trim() ?? '');
                  if (day == null || day < 1 || day > 31) {
                    return 'Masukkan tanggal 1 - 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: noteController,
                hintText: 'Catatan tambahan (Opsional)',
                prefixIcon: Icons.sticky_note_2_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEdit ? 'Simpan Perubahan' : 'Tambah Pengingat Tagihan',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final amount = double.parse(amountController.text.replaceAll(',', '').trim());
                    final dueDay = int.parse(dueDayController.text.trim());
                    final title = titleController.text.trim();
                    final note = noteController.text.trim();

                    if (isEdit) {
                      await budgetProvider.updateBill(
                        authProvider.user!.id,
                        bill.copyWith(
                          title: title,
                          amount: amount,
                          dueDay: dueDay,
                          note: note,
                        ),
                      );
                    } else {
                      final newBill = BillReminder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        amount: amount,
                        dueDay: dueDay,
                        isPaid: false,
                        note: note,
                      );
                      await budgetProvider.addBill(authProvider.user!.id, newBill);
                    }

                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payAndRecordTransaction(BillReminder bill) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final confirmed = await showAnimatedPopup<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.incomeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bayar Tagihan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Tandai tagihan "${bill.title}" sebagai lunas dan otomatis catat pengeluaran sebesar ${currency.format(bill.amount)} ke buku transaksi?',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Bayar & Catat'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final expenseCategories = transactionProvider.getCategoriesByType('expense');
      int categoryId = 1;
      if (expenseCategories.isNotEmpty) {
        final match = expenseCategories.firstWhere(
          (c) =>
              c.name.toLowerCase().contains('house') ||
              c.name.toLowerCase().contains('kos') ||
              c.name.toLowerCase().contains('util') ||
              c.name.toLowerCase().contains('listrik'),
          orElse: () => expenseCategories.first,
        );
        categoryId = match.id;
      }

      final tx = Transaction(
        userId: authProvider.user!.id,
        title: 'Tagihan: ${bill.title}',
        amount: bill.amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: categoryId,
        note: bill.note ?? 'Pembayaran tagihan rutin',
      );

      final success = await transactionProvider.addTransaction(
        tx,
        authProvider.user!.token,
      );

      if (success) {
        if (!bill.isPaid) {
          await budgetProvider.toggleBillPaid(authProvider.user!.id, bill.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.income,
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Tagihan berhasil dibayar & dicatat!'),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final bills = budgetProvider.bills;
    final filteredBills = bills.where((b) {
      if (_filterIndex == 1) return !b.isPaid;
      if (_filterIndex == 2) return b.isPaid;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tagihan & Pengingat Kos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Tagihan',
            onPressed: () => _showAddEditBillDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showAddEditBillDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Tagihan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Hero Summary Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: budgetProvider.pendingBillsCount > 0
                                    ? AppColors.cream
                                    : AppColors.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tagihan Belum Lunas',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(budgetProvider.pendingBillsTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${budgetProvider.pendingBillsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Tertunda',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Segmented Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildFilterTab(0, 'Semua (${bills.length})'),
                  _buildFilterTab(1, 'Belum Lunas (${budgetProvider.pendingBillsCount})'),
                  _buildFilterTab(2, 'Lunas (${bills.length - budgetProvider.pendingBillsCount})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bills List
          Expanded(
            child: filteredBills.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: AppColors.incomeLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              size: 36,
                              color: AppColors.income,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterIndex == 1
                                ? 'Semua tagihan sudah lunas!'
                                : 'Belum ada tagihan tersimpan.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filterIndex == 1
                                ? 'Dompet dan pikiranmu aman untuk bulan ini.'
                                : 'Catat uang kos, listrik, air, atau WiFi agar teratur.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90, top: 8),
                    itemCount: filteredBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bill = filteredBills[index];
                      final today = DateTime.now().day;
                      final daysLeft = bill.dueDay - today;

                      String dueText;
                      Color statusBg;
                      Color statusFg;
                      IconData statusIcon;

                      if (bill.isPaid) {
                        dueText = 'Sudah Lunas';
                        statusBg = AppColors.incomeLight;
                        statusFg = AppColors.income;
                        statusIcon = Icons.check_circle_rounded;
                      } else if (daysLeft < 0) {
                        dueText = 'Lewat ${-daysLeft} hari lalu';
                        statusBg = AppColors.expenseLight;
                        statusFg = AppColors.expense;
                        statusIcon = Icons.warning_amber_rounded;
                      } else if (daysLeft == 0) {
                        dueText = 'Jatuh tempo HARI INI!';
                        statusBg = AppColors.warningLight;
                        statusFg = AppColors.warning;
                        statusIcon = Icons.alarm_rounded;
                      } else {
                        dueText = '$daysLeft hari lagi (Tgl ${bill.dueDay})';
                        statusBg = AppColors.primaryLight;
                        statusFg = AppColors.primary;
                        statusIcon = Icons.calendar_month_rounded;
                      }

                      final catColor = AppColors.getCategoryColor(bill.title);
                      final catIcon = AppColors.getCategoryIcon(bill.title);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: bill.isPaid
                                ? AppColors.border
                                : (daysLeft <= 0 ? AppColors.expense.withValues(alpha: 0.4) : AppColors.border),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: bill.isPaid
                                          ? AppColors.surfaceMuted
                                          : catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      catIcon,
                                      color: bill.isPaid ? AppColors.textMuted : catColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: bill.isPaid
                                                ? AppColors.textMuted
                                                : AppColors.textPrimary,
                                            decoration: bill.isPaid
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: 13, color: statusFg),
                                              const SizedBox(width: 4),
                                              Text(
                                                dueText,
                                                style: TextStyle(
                                                  color: statusFg,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(bill.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: bill.isPaid
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (bill.note != null && bill.note!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  bill.note!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => _showAddEditBillDialog(bill: bill),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 15, color: AppColors.textSecondary),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          if (authProvider.user != null) {
                                            await budgetProvider.deleteBill(
                                              authProvider.user!.id,
                                              bill.id,
                                            );
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded,
                                                  size: 15, color: AppColors.expense),
                                              SizedBox(width: 4),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.expense,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!bill.isPaid)
                                    FilledButton.icon(
                                      onPressed: () => _payAndRecordTransaction(bill),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.income,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text(
                                        'Bayar & Catat',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () async {
                                        if (authProvider.user != null) {
                                          await budgetProvider.toggleBillPaid(
                                            authProvider.user!.id,
                                            bill.id,
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textSecondary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                      icon: const Icon(Icons.undo_rounded, size: 15),
                                      label: const Text(
                                        'Batal Lunas',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String title) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
