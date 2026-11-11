import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/screens/register_screen.dart';
import 'package:kos_finance_app/screens/home_screen.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';
import 'package:kos_finance_app/widgets/app_logo.dart';
import 'package:kos_finance_app/widgets/server_settings_dialog.dart';
import 'package:kos_finance_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            tooltip: 'Pengaturan Server API',
            onPressed: () => showServerSettingsDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 72)),
                  const SizedBox(height: 20),
                  const Text(
                    'Masuk ke Kos Finance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola uang saku, catatan harian, & tagihan kos',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (authProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.expenseLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: const TextStyle(color: AppColors.expense, fontSize: 13, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                          if (authProvider.error!.contains('server') || authProvider.error!.contains('terhubung')) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                ),
                                icon: const Icon(Icons.dns_rounded, size: 14, color: AppColors.primary),
                                label: const Text('Atur Alamat Server', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                onPressed: () => showServerSettingsDialog(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'nama@email.com',
                    labelText: 'Email',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan alamat email Anda';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '••••••••',
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan password Anda';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Masuk Sekarang',
                    icon: Icons.login_rounded,
                    isLoading: authProvider.isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ATAU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final success = await authProvider.loginGuest();
                      if (success && mounted) {
                        nav.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.offline_bolt_rounded, size: 20, color: AppColors.primary),
                    label: const Text(
                      'Lanjut Mode Offline (Tanpa Server)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        child: const Text(
                          'Daftar Akun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
