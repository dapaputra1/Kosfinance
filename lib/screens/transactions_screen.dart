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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

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
    return transactions.where((t) {
      // 1. Month filter
      final transactionMonth = DateTime(t.date.year, t.date.month, 1);
      final selectedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      if (!transactionMonth.isAtSameMomentAs(selectedMonth)) return false;

      // 2. Type filter
      if (type != null && t.type != type) return false;

      // 3. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchNote = t.note?.toLowerCase().contains(query) ?? false;
        final matchCat = t.categoryName?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchNote && !matchCat) return false;
      }

      // 4. Category filter
      if (_selectedCategory != null && t.categoryName != _selectedCategory) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

    // WhatsApp friendly text
    final buffer = StringBuffer();
    buffer.writeln('🏠 LAPORAN KEUANGAN KOS - $_selectedMonth');
    buffer.writeln('👤 Nama: ${authProvider.user?.name ?? "Anak Kos"}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 Total Pemasukan : ${currencyFormat.format(totalIncome)}');
    buffer.writeln('💸 Total Pengeluaran: ${currencyFormat.format(totalExpense)}');
    buffer.writeln('💵 Sisa Kas Akhir   : ${currencyFormat.format(balance)}');
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

    // CSV text
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Tanggal,Judul,Tipe,Kategori,Nominal,Catatan');
    for (final tx in monthTransactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      final typeStr = tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
      final titleStr = '"${tx.title.replaceAll('"', '""')}"';
      final catStr = '"${(tx.categoryName ?? "").replaceAll('"', '""')}"';
      final noteStr = '"${(tx.note ?? "").replaceAll('"', '""')}"';
      csvBuffer.writeln('$dateStr,$titleStr,$typeStr,$catStr,${tx.amount.toInt()},$noteStr');
    }
    final csvText = csvBuffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Bagikan Laporan Keuangan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  reportText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reportText));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Laporan disalin! Siap dikirim ke WhatsApp.')),
                            ],
                          ),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvText));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: const Row(
                            children: [
                              Icon(Icons.table_chart_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Format CSV disalin! Siap di-paste ke Excel / Sheets.')),
                            ],
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Salin CSV',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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

    // Get list of unique category names from existing transactions
    final availableCategories = transactionProvider.transactions
        .map((t) => t.categoryName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
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
          // Month Selector & Search Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              items: _months.map((month) {
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(month, overflow: TextOverflow.ellipsis),
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
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips (if categories exist)
          if (availableCategories.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('Semua Kategori'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.w500,
                        color: _selectedCategory == null ? AppColors.primary : AppColors.textSecondary,
                      ),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primaryLight,
                      showCheckmark: false,
                      side: BorderSide(
                        color: _selectedCategory == null ? AppColors.primary : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ...availableCategories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final catColor = AppColors.getCategoryColor(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? catColor : AppColors.textSecondary,
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = isSelected ? null : cat;
                          });
                        },
                        backgroundColor: AppColors.surface,
                        selectedColor: catColor.withValues(alpha: 0.14),
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected ? catColor : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Custom Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada transaksi dengan kata "$_searchQuery"'
                  : 'Tidak ada transaksi di periode ini',
              style: const TextStyle(
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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 80),
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
