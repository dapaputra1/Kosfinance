import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/providers/budget_provider.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/screens/splash_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Kos Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
