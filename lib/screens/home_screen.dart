import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/screens/add_transaction_screen.dart';
import 'package:kos_finance_app/screens/bills_screen.dart';
import 'package:kos_finance_app/screens/profile_screen.dart';
import 'package:kos_finance_app/screens/transactions_screen.dart';
import 'package:kos_finance_app/widgets/budget_card.dart';
import 'package:kos_finance_app/widgets/dashboard_card.dart';
import 'package:kos_finance_app/widgets/recent_transaction_item.dart';
import 'package:kos_finance_app/widgets/spending_pie_chart.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const BillsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await Future.wait([
        transactionProvider.fetchTransactions(authProvider.user!.token),
        transactionProvider.fetchCategories(authProvider.user!.token),
        transactionProvider.fetchDashboardData(authProvider.user!.token),
        budgetProvider.loadData(authProvider.user!.id),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'Tagihan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final double balance = (transactionProvider.dashboardData['balance'] as num?)?.toDouble() ?? 0.0;
    final double totalIncome = (transactionProvider.dashboardData['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final double totalExpense = (transactionProvider.dashboardData['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final double monthlyIncome = (transactionProvider.dashboardData['monthlyIncome'] as num?)?.toDouble() ?? 0.0;
    final double monthlyExpense = (transactionProvider.dashboardData['monthlyExpense'] as num?)?.toDouble() ?? 0.0;
    final double thisMonthNet = monthlyIncome - monthlyExpense;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.user != null) {
            final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
            await Future.wait([
              transactionProvider.fetchTransactions(authProvider.user!.token),
              transactionProvider.fetchDashboardData(authProvider.user!.token),
              budgetProvider.loadData(authProvider.user!.id),
            ]);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // User Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          (authProvider.user?.name.isNotEmpty ?? false)
                              ? authProvider.user!.name[0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          authProvider.user?.name ?? 'Anak Kos',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.incomeLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.income, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Keuangan Aktif',
                        style: TextStyle(
                          color: AppColors.income,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hero Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: Colors.white.withValues(alpha: 0.85), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Total Saldo Kas',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'IDR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currencyFormat.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: Color(0xFF34D399), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            currencyFormat.format(totalIncome),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: Color(0xFFF87171), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            currencyFormat.format(totalExpense),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Pemasukan Bulan Ini',
                    amount: currencyFormat.format(monthlyIncome),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: 'Pengeluaran Bulan Ini',
                    amount: currencyFormat.format(monthlyExpense),
                    icon: Icons.trending_down_rounded,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Monthly Net Card
            DashboardCard(
              title: 'Net Arus Kas Bulan Ini',
              amount: currencyFormat.format(thisMonthNet),
              icon: thisMonthNet >= 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
              color: thisMonthNet >= 0 ? AppColors.income : AppColors.expense,
              subtitle: thisMonthNet >= 0 ? 'Surplus Finansial' : 'Defisit Bulan Ini',
            ),
            const SizedBox(height: 16),

            // Budgeting Card
            const BudgetCard(),
            const SizedBox(height: 16),

            // Spending Pie Chart
            SpendingPieChart(
              categoryExpenses: transactionProvider.dashboardData['categoryExpenses'] is List
                  ? (transactionProvider.dashboardData['categoryExpenses'] as List)
                  : [],
            ),
            const SizedBox(height: 20),

            // Recent Transactions Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terakhir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Row(
                    children: [
                      Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Transactions List
            if (transactionProvider.recentTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada transaksi.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tekan tombol + di bawah untuk mulai mencatat.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactionProvider.recentTransactions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final transaction = transactionProvider.recentTransactions[index];
                    return RecentTransactionItem(
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
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
