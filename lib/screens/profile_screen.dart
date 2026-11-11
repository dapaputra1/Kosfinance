import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/screens/login_screen.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';
import 'package:kos_finance_app/widgets/server_settings_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.user?.name ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
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
              const Row(
                children: [
                  Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Edit Profil Pengguna',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: nameController,
                hintText: 'Nama Lengkap',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: passwordController,
                hintText: 'Password Baru (Kosongkan jika tidak ganti)',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: 'Konfirmasi Password Baru',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: true,
                validator: (val) {
                  if (passwordController.text.isNotEmpty && val != passwordController.text) {
                    return 'Password konfirmasi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Simpan Perubahan',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final pass = passwordController.text.isNotEmpty
                        ? passwordController.text
                        : null;
                    final success = await authProvider.updateProfile(
                      nameController.text.trim(),
                      pass,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: Text(
                            success
                                ? 'Profil berhasil diperbarui!'
                                : (authProvider.error ?? 'Gagal memperbarui profil'),
                          ),
                          backgroundColor:
                              success ? AppColors.income : AppColors.expense,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scrollController,
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tips Finansial Anak Kos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTipItem(
                '1. Terapkan Rumus 50 / 30 / 20',
                'Bagi kiriman bulananmu: 50% untuk kebutuhan pokok (makan, bayar kos, listrik), 30% untuk kebutuhan kuliah/lifestyle terencana, dan 20% langsung tabung sebagai dana darurat.',
                Icons.pie_chart_outline_rounded,
                AppColors.primary,
              ),
              _buildTipItem(
                '2. Pantau Tagihan Rutin Kos',
                'Catat tanggal jatuh tempo uang kos, air, laundry, dan token listrik di menu Tagihan agar tidak kena denda atau terlambat bayar.',
                Icons.notifications_active_outlined,
                AppColors.warning,
              ),
              _buildTipItem(
                '3. Pasang Target Budget Bulanan',
                'Tetapkan batas pengeluaran maksimal di Dashboard. Aplikasi akan memberikan peringatan visual jika sisa uangmu di bawah batas aman.',
                Icons.track_changes_rounded,
                AppColors.income,
              ),
              _buildTipItem(
                '4. Evaluasi Lewat Diagram Pengeluaran',
                'Cek grafik pengeluaran setiap akhir pekan untuk mengetahui kategori mana yang paling boros (e.g. nongkrong kafe, jajan ojol, atau belanja online).',
                Icons.insights_rounded,
                AppColors.purple,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Punya kendala teknis atau saran fitur baru? Kontak tim KosFinance di support@kosfinance.app',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTipItem(
    String title,
    String desc,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Akun'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // User Hero Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.aqua],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@example.com',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Anak Kos Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Akun & Keamanan
            _buildSectionHeader('AKUN & PENGATURAN'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Edit Profil',
                subtitle: 'Ubah nama tampilan atau perbarui password',
                onTap: () => _showEditProfileDialog(context, authProvider),
              ),
              _buildSettingsTile(
                icon: Icons.dns_rounded,
                iconColor: AppColors.primary,
                title: 'Koneksi Server API',
                subtitle: 'Ganti alamat backend (Localhost / Android)',
                onTap: () => showServerSettingsDialog(context),
              ),
            ]),
            const SizedBox(height: 20),

            // Section 2: Edukasi & Bantuan
            _buildSectionHeader('BANTUAN & INFORMASI'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.tips_and_updates_outlined,
                iconColor: AppColors.warning,
                title: 'Tips Finansial Anak Kos',
                subtitle: 'Strategi atur uang bulanan & tips hemat',
                onTap: () => _showHelpSupportDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.purple,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0 • Dibuat khusus mahasiswa & anak kos',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Kos Finance',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    children: const [
                      SizedBox(height: 12),
                      Text(
                        'Kos Finance adalah platform pencatatan keuangan pribadi untuk mahasiswa dan anak kos. Dilengkapi pencatatan transaksi, target budget bulanan, dan pengingat tagihan kos.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  );
                },
              ),
            ]),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Keluar dari Akun?'),
                    content: const Text(
                      'Apakah kamu yakin ingin logout dari aplikasi Kos Finance?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Ya, Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.expense, size: 20),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.expense.withValues(alpha: 0.35), width: 1.5),
                backgroundColor: AppColors.expenseLight.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
