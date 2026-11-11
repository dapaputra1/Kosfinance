import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/providers/savings_provider.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/screens/splash_screen.dart';
import 'package:kos_finance_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initBaseUrl();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
      ],
      child: MaterialApp(
        title: 'Kos Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
