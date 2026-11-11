import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/models/bill_model.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Tagihan' : 'Tambah Tagihan Baru',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: titleController,
                hintText: 'Nama Tagihan (e.g. Kamar Kos, Token Listrik)',
                prefixIcon: Icons.receipt_long,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Masukkan nama tagihan' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: amountController,
                hintText: 'Nominal Tagihan (Rp)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Masukkan nominal';
                  if (double.tryParse(val.replaceAll(',', '')) == null) {
                    return 'Nominal tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: dueDayController,
                hintText: 'Tanggal Jatuh Tempo Bulanan (1 - 31)',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (val) {
                  final day = int.tryParse(val ?? '');
                  if (day == null || day < 1 || day > 31) {
                    return 'Masukkan tanggal 1 - 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: noteController,
                hintText: 'Catatan (Opsional)',
                prefixIcon: Icons.note_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: isEdit ? 'Simpan Perubahan' : 'Tambah Tagihan',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final amount = double.parse(amountController.text.replaceAll(',', ''));
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

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bayar Tagihan & Catat Transaksi?'),
        content: Text(
          'Tindakan ini akan menandai tagihan "${bill.title}" sebagai lunas dan secara otomatis menambahkan pengeluaran sebesar Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(bill.amount)} ke catatan transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Bayar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Find category: prioritize 'Housing' or 'Utilities' or first expense category
      final expenseCategories = transactionProvider.getCategoriesByType('expense');
      int categoryId = 1;
      if (expenseCategories.isNotEmpty) {
        final match = expenseCategories.firstWhere(
          (c) =>
              c.name.toLowerCase().contains('house') ||
              c.name.toLowerCase().contains('kos') ||
              c.name.toLowerCase().contains('util'),
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
            const SnackBar(
              content: Text('Tagihan berhasil dibayar & tercatat ke pengeluaran!'),
              backgroundColor: Colors.green,
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
      appBar: AppBar(
        title: const Text('Tagihan & Pengingat Kos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBillDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tagihan'),
      ),
      body: Column(
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.indigo.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Belum Dibayar',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(budgetProvider.pendingBillsTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${budgetProvider.pendingBillsCount} Tagihan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _filterIndex == 0,
                  onSelected: (val) => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Belum Lunas (${budgetProvider.pendingBillsCount})'),
                  selected: _filterIndex == 1,
                  onSelected: (val) => setState(() => _filterIndex = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Lunas'),
                  selected: _filterIndex == 2,
                  onSelected: (val) => setState(() => _filterIndex = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Bills List
          Expanded(
            child: filteredBills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _filterIndex == 1
                              ? 'Semua tagihan sudah lunas! Aman!'
                              : 'Belum ada tagihan terdaftar.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                    itemCount: filteredBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = filteredBills[index];
                      final today = DateTime.now().day;
                      final daysLeft = bill.dueDay - today;

                      String dueText;
                      Color dueColor;
                      if (bill.isPaid) {
                        dueText = 'Sudah Lunas';
                        dueColor = Colors.green;
                      } else if (daysLeft < 0) {
                        dueText = 'Lewat ${-daysLeft} hari lalu!';
                        dueColor = Colors.red.shade700;
                      } else if (daysLeft == 0) {
                        dueText = 'Jatuh tempo HARI INI!';
                        dueColor = Colors.orange.shade800;
                      } else {
                        dueText = 'Jatuh tempo $daysLeft hari lagi (Tgl ${bill.dueDay})';
                        dueColor = Colors.blue.shade700;
                      }

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: bill.isPaid
                                ? Colors.green.shade200
                                : (daysLeft <= 0 ? Colors.red.shade200 : Colors.grey.shade200),
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
                                  CircleAvatar(
                                    backgroundColor: bill.isPaid
                                        ? Colors.green.shade50
                                        : Colors.blue.shade50,
                                    child: Icon(
                                      bill.title.toLowerCase().contains('kamar') ||
                                              bill.title.toLowerCase().contains('kos')
                                          ? Icons.home_outlined
                                          : (bill.title.toLowerCase().contains('listrik')
                                              ? Icons.bolt_outlined
                                              : Icons.receipt_outlined),
                                      color: bill.isPaid
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration: bill.isPaid
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dueText,
                                          style: TextStyle(
                                            color: dueColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(bill.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: bill.isPaid
                                          ? Colors.grey
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (bill.note != null && bill.note!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  bill.note!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        onPressed: () =>
                                            _showAddEditBillDialog(bill: bill),
                                        tooltip: 'Edit Tagihan',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.red),
                                        onPressed: () async {
                                          if (authProvider.user != null) {
                                            await budgetProvider.deleteBill(
                                              authProvider.user!.id,
                                              bill.id,
                                            );
                                          }
                                        },
                                        tooltip: 'Hapus Tagihan',
                                      ),
                                    ],
                                  ),
                                  if (!bill.isPaid)
                                    ElevatedButton.icon(
                                      onPressed: () => _payAndRecordTransaction(bill),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text(
                                        'Bayar & Catat',
                                        style: TextStyle(fontSize: 12),
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
                                      icon: const Icon(Icons.undo, size: 16),
                                      label: const Text('Batal Lunas'),
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
}
