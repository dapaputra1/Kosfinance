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
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      authProvider.user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (authProvider.user?.name.isNotEmpty ?? false)
                        ? authProvider.user!.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (transactionProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Balance',
                          amount: currencyFormat.format(
                            transactionProvider.dashboardData['balance'] ?? 0,
                          ),
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'Income',
                          amount: currencyFormat.format(
                            transactionProvider.dashboardData['totalIncome'] ?? 0,
                          ),
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Expenses',
                          amount: currencyFormat.format(
                            transactionProvider.dashboardData['totalExpense'] ?? 0,
                          ),
                          icon: Icons.arrow_downward,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'This Month',
                          amount: currencyFormat.format(
                            (transactionProvider.dashboardData['monthlyIncome'] ?? 0) -
                                (transactionProvider.dashboardData['monthlyExpense'] ?? 0),
                          ),
                          icon: Icons.calendar_today,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const BudgetCard(),
                  const SizedBox(height: 16),
                  SpendingPieChart(
                    categoryExpenses: transactionProvider.dashboardData['categoryExpenses'] is List
                        ? (transactionProvider.dashboardData['categoryExpenses'] as List)
                        : [],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (transactionProvider.recentTransactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No transactions yet. Add your first transaction!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
