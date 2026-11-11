import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    final initialIndex = (t != null && t.type == TransactionType.expense) ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) {
        _syncCategoryForTab();
        setState(() {});
      }
    });

    if (t != null) {
      _titleController.text = t.title;
      _amountController.text =
          t.amount % 1 == 0 ? t.amount.toInt().toString() : t.amount.toString();
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      _selectedCategoryId = t.categoryId;
    }

    // Pre-fetch categories if empty and select default
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tp = Provider.of<TransactionProvider>(context, listen: false);
      final ap = Provider.of<AuthProvider>(context, listen: false);
      final token = ap.user?.token ?? 'offline_token_1';
      if (tp.categories.isEmpty) {
        await tp.fetchCategories(token);
      }
      if (mounted && _selectedCategoryId == null) {
        _syncCategoryForTab();
      }
    });
  }

  void _syncCategoryForTab() {
    final tp = Provider.of<TransactionProvider>(context, listen: false);
    final isExpense = _tabController.index == 1;
    final currentCats = tp.getCategoriesByType(isExpense ? 'expense' : 'income');
    if (currentCats.isNotEmpty) {
      setState(() {
        _selectedCategoryId = currentCats.first.id;
      });
    }
  }

  String _formatSelectedDate(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];
      return '$dayName, ${date.day} $monthName ${date.year}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'e.g. Laundry, Buku, Fotokopi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final type = _tabController.index == 0 ? 'income' : 'expense';
                final token = authProvider.user?.token ?? 'offline_token_1';
                final newCat = await transactionProvider.addCategory(
                  name,
                  'tag',
                  type,
                  token,
                );
                if (newCat != null) {
                  setState(() {
                    _selectedCategoryId = newCat.id;
                  });
                }
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih salah satu kategori terlebih dahulu'),
            backgroundColor: AppColors.expense,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      final user = authProvider.user;
      final userId = user?.id ?? 1;
      final token = user?.token ?? 'offline_token_1';

      final isExpense = _tabController.index == 1;
      final type = isExpense ? TransactionType.expense : TransactionType.income;
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      bool success;
      if (widget.transaction != null) {
        final updatedTx = widget.transaction!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: type,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim(),
        );
        success = await transactionProvider.updateTransaction(
          updatedTx,
          token,
        );
      } else {
        final newTx = Transaction(
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: type,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim(),
        );
        success = await transactionProvider.addTransaction(
          newTx,
          token,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction != null
                  ? 'Transaksi berhasil diperbarui!'
                  : 'Transaksi berhasil dicatat!',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final isExpense = _tabController.index == 1;
    final activeColor = isExpense ? AppColors.expense : AppColors.income;

    final categories = transactionProvider
        .getCategoriesByType(isExpense ? 'expense' : 'income');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaksi' : 'Catat Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Segmented Type Selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Pemasukan (+)'),
                  Tab(text: 'Pengeluaran (-)'),
                ],
                onTap: (_) {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Prominent Amount Input Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal Transaksi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan nominal transaksi';
                      }
                      if (double.tryParse(value.replaceAll(',', '')) == null) {
                        return 'Nominal tidak valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title Input
            CustomTextField(
              controller: _titleController,
              hintText: 'e.g. Makan siang warteg, Uang saku ortu',
              labelText: 'Judul Transaksi',
              prefixIcon: Icons.edit_note_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Masukkan judul transaksi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Selector Card
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            _formatSelectedDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Kategori Baru', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Chips Grid
            if (transactionProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = _selectedCategoryId == category.id;
                  final catColor = AppColors.getCategoryColor(category.name);
                  final catIcon = AppColors.getCategoryIcon(category.name);

                  return ChoiceChip(
                    avatar: Icon(
                      catIcon,
                      size: 16,
                      color: isSelected ? Colors.white : catColor,
                    ),
                    label: Text(category.name),
                    selected: isSelected,
                    selectedColor: catColor,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? catColor : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Note input
            CustomTextField(
              controller: _noteController,
              hintText: 'Tambahkan catatan jika perlu (opsional)',
              labelText: 'Catatan',
              prefixIcon: Icons.sticky_note_2_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            // Save Button
            CustomButton(
              text: widget.transaction != null ? 'Perbarui Transaksi' : 'Simpan Transaksi',
              icon: Icons.check_circle_outline_rounded,
              color: activeColor,
              isLoading: transactionProvider.isLoading,
              onPressed: _saveTransaction,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
