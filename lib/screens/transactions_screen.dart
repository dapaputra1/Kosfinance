import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/widgets/transaction_item.dart';
import 'package:kos_finance_app/screens/add_transaction_screen.dart';
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

  void _shareMonthlyReport(
    BuildContext context,
    TransactionProvider transactionProvider,
    AuthProvider authProvider,
  ) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthTransactions =
        _filterTransactions(transactionProvider.transactions, null);

    final double totalIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double balance = totalIncome - totalExpense;

    final buffer = StringBuffer();
    buffer.writeln('🏠 LAPORAN KEUANGAN KOS - $_selectedMonth');
    buffer.writeln('👤 Nama: ${authProvider.user?.name ?? "Anak Kos"}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 Pemasukan  : ${currencyFormat.format(totalIncome)}');
    buffer.writeln('💸 Pengeluaran: ${currencyFormat.format(totalExpense)}');
    buffer.writeln('💵 Sisa Kas   : ${currencyFormat.format(balance)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📝 Rincian Transaksi:');

    if (monthTransactions.isEmpty) {
      buffer.writeln('(Belum ada transaksi di bulan ini)');
    } else {
      for (final tx in monthTransactions) {
        final symbol = tx.type == TransactionType.income ? '[+]' : '[-]';
        final cat = tx.categoryName != null ? ' (${tx.categoryName})' : '';
        buffer.writeln(
            '$symbol ${DateFormat("dd/MM").format(tx.date)} ${tx.title}$cat: ${currencyFormat.format(tx.amount)}');
      }
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Dicatat via Aplikasi Kos Finance');

    final reportText = buffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Bagikan Laporan Keuangan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  reportText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Laporan berhasil disalin! Siap dikirim ke WhatsApp/Orang Tua.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Salin Laporan ke Clipboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan Laporan',
            onPressed: () => _shareMonthlyReport(
              context,
              transactionProvider,
              authProvider,
            ),
          ),
        ],
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
              initialValue: _selectedMonth,
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
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(transaction: transaction),
                ),
              );
            },
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
