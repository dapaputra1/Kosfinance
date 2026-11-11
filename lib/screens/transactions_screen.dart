import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/widgets/transaction_item.dart';
import 'package:kos_finance_app/screens/add_transaction_screen.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Bagikan Laporan Keuangan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  reportText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
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
                    content: Text('Laporan berhasil disalin! Siap dikirim ke WhatsApp/Orang Tua.'),
                    backgroundColor: AppColors.income,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Salin Laporan ke Clipboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
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
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            tooltip: 'Bagikan Laporan',
            onPressed: () => _shareMonthlyReport(
              context,
              transactionProvider,
              authProvider,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                  ),
                ],
              ),
            ),
          ),

          // Custom Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Pemasukan'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),

          // Tab views
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 52, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada transaksi di periode ini',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        if (authProvider.user != null) {
          await transactionProvider.fetchTransactions(authProvider.user!.token);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
