import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/widgets/transaction_item.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateMonths();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('MMMM yyyy').format(month));
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions, TransactionType? type) {
    final selectedDate = DateFormat('MMMM yyyy').parse(_selectedMonth);
    final filteredByMonth = transactions.where((t) {
      final transactionMonth = DateTime(t.date.year, t.date.month, 1);
      final selectedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      return transactionMonth.isAtSameMomentAs(selectedMonth);
    }).toList();

    if (type != null) {
      return filteredByMonth.where((t) => t.type == type).toList();
    }
    return filteredByMonth;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
              ),
              items: _months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(
                  _filterTransactions(transactionProvider.transactions, null),
                  authProvider,
                  transactionProvider,
                ),
                _buildTransactionList(
                  _filterTransactions(transactionProvider.transactions, TransactionType.income),
                  authProvider,
                  transactionProvider,
                ),
                _buildTransactionList(
                  _filterTransactions(transactionProvider.transactions, TransactionType.expense),
                  authProvider,
                  transactionProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<Transaction> transactions,
    AuthProvider authProvider,
    TransactionProvider transactionProvider,
  ) {
    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found for this period',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (authProvider.user != null) {
          await transactionProvider.fetchTransactions(authProvider.user!.token);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return TransactionItem(
            transaction: transaction,
            onDelete: () async {
              if (transaction.id != null && authProvider.user != null) {
                await transactionProvider.deleteTransaction(
                  transaction.id!,
                  authProvider.user!.token,
                );
              }
            },
          );
        },
      ),
    );
  }
}
