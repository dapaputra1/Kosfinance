import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/models/category_model.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';
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
    if (t != null) {
      _titleController.text = t.title;
      _amountController.text =
          t.amount % 1 == 0 ? t.amount.toInt().toString() : t.amount.toString();
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      _selectedCategoryId = t.categoryId;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      if (authProvider.user == null) return;

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
          authProvider.user!.token,
        );
      } else {
        final newTx = Transaction(
          userId: authProvider.user!.id,
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: type,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim(),
        );
        success = await transactionProvider.addTransaction(
          newTx,
          authProvider.user!.token,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
          onTap: (_) {
            setState(() {
              _selectedCategoryId = null;
            });
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _titleController,
              hintText: 'Title',
              prefixIcon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _amountController,
              hintText: 'Amount',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value.replaceAll(',', '')) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (transactionProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: transactionProvider
                    .getCategoriesByType(_tabController.index == 0 ? 'income' : 'expense')
                    .map((category) {
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _noteController,
              hintText: 'Note (Optional)',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: widget.transaction != null ? 'Update Transaction' : 'Save Transaction',
              isLoading: transactionProvider.isLoading,
              onPressed: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }
}
