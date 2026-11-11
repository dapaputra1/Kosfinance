import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/screens/add_transaction_screen.dart';
import 'package:kos_finance_app/screens/bills_screen.dart';
import 'package:kos_finance_app/screens/profile_screen.dart';
import 'package:kos_finance_app/screens/transactions_screen.dart';
import 'package:kos_finance_app/widgets/animated_popup.dart';
import 'package:kos_finance_app/widgets/budget_card.dart';
import 'package:kos_finance_app/widgets/dashboard_card.dart';
import 'package:kos_finance_app/widgets/recent_transaction_item.dart';
import 'package:kos_finance_app/widgets/spending_pie_chart.dart';
import 'package:kos_finance_app/widgets/split_bill_dialog.dart';
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
      floatingActionButton: AnimatedTapScale(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: FloatingActionButton(
          onPressed: null,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
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
        color: AppColors.primary,
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
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
            ),
            const SizedBox(height: 16),

            // Hero Balance Card
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 100),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Text(
                            'IDR',
                            style: TextStyle(
                              color: Colors.white,
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
                            const Icon(Icons.arrow_upward_rounded, color: Color(0xFFB4E3B6), size: 16),
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
                            const Icon(Icons.arrow_downward_rounded, color: Color(0xFFF7B1A5), size: 16),
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
            ),
            const SizedBox(height: 14),

            // Quick Actions Bar (Varied interactive tools)
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 140),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.add_rounded,
                      label: 'Catat Baru',
                      accentColor: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.calculate_rounded,
                      label: 'Patungan',
                      accentColor: const Color(0xFFC75846),
                      onTap: () => showSplitBillDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.event_note_rounded,
                      label: 'Tagihan Kos',
                      accentColor: AppColors.warning,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BillsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Metrics Row
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 180),
              child: Row(
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
            ),
            const SizedBox(height: 12),

            // Monthly Net Card
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 220),
              child: DashboardCard(
                title: 'Net Arus Kas Bulan Ini',
                amount: currencyFormat.format(thisMonthNet),
                icon: thisMonthNet >= 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                color: thisMonthNet >= 0 ? AppColors.income : AppColors.expense,
                subtitle: thisMonthNet >= 0 ? 'Surplus Finansial' : 'Defisit Bulan Ini',
              ),
            ),
            const SizedBox(height: 16),

            // Budgeting Card
            const FadeSlideEntrance(
              delay: Duration(milliseconds: 260),
              child: BudgetCard(),
            ),
            const SizedBox(height: 16),

            // Spending Pie Chart
            FadeSlideEntrance(
              delay: const Duration(milliseconds: 300),
              child: SpendingPieChart(
                categoryExpenses: transactionProvider.dashboardData['categoryExpenses'] is List
                    ? (transactionProvider.dashboardData['categoryExpenses'] as List)
                    : [],
              ),
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
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  itemCount: transactionProvider.recentTransactions.length > 5
                      ? 5
                      : transactionProvider.recentTransactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
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
                    );
                  },
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
