import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/screens/login_screen.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/widgets/custom_button.dart';
import 'package:kos_finance_app/widgets/custom_text_field.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nameController,
                hintText: 'Nama Lengkap',
                prefixIcon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: passwordController,
                hintText: 'Password Baru (Kosongkan jika tidak ganti)',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: confirmPasswordController,
                hintText: 'Konfirmasi Password Baru',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (val) {
                  if (passwordController.text.isNotEmpty && val != passwordController.text) {
                    return 'Password konfirmasi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Simpan Profil',
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
                          content: Text(
                            success
                                ? 'Profil berhasil diperbarui!'
                                : (authProvider.error ?? 'Gagal memperbarui profil'),
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
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

  void _showSettingsDialog(BuildContext context) {
    final urlController = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan Server API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah alamat server backend sesuai perangkat yang Anda gunakan:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL Backend',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Android (10.0.2.2)'),
                  onPressed: () {
                    urlController.text = 'http://10.0.2.2:3000/api';
                  },
                ),
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () {
                    urlController.text = 'http://localhost:3000/api';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiService.setBaseUrl(newUrl);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server API diubah ke: $newUrl'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Text(
                    'Tips Finansial Anak Kos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                '1. Gunakan Rumus 50 - 30 - 20',
                'Bagi kiriman bulananmu: 50% untuk kebutuhan pokok (makan, bayar kos, listrik), 30% untuk kebutuhan kuliah/pribadi, dan 20% untuk tabungan/dana darurat.',
              ),
              _buildTipItem(
                '2. Pantau Tagihan Rutin Kos',
                'Catat tanggal jatuh tempo uang kos dan token listrik di menu "Tagihan" agar tidak terlambat dan kena denda.',
              ),
              _buildTipItem(
                '3. Pasang Target Budget Bulanan',
                'Tetapkan batas pengeluaran maksimal di Dashboard. Aplikasi akan memberikan peringatan visual jika jatah bulananmu hampir habis.',
              ),
              _buildTipItem(
                '4. Evaluasi Lewat Diagram Pengeluaran',
                'Cek grafik pengeluaran di Dashboard setiap akhir pekan untuk mengetahui kategori apa yang paling banyak menghabiskan uangmu (e.g. jajan, kopi, belanja online).',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Punya kendala atau saran fitur? Hubungi kami di support@kosfinance.app',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTipItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (authProvider.user?.name.isNotEmpty ?? false)
                    ? authProvider.user!.name[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.user?.name ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              authProvider.user?.email ?? 'email@example.com',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              subtitle: const Text('Ubah nama dan password akun'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditProfileDialog(context, authProvider),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Konfigurasi server backend API'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSettingsDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              subtitle: const Text('Tips finansial & kontak bantuan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showHelpSupportDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Informasi aplikasi Kos Finance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Kos Finance',
                  applicationVersion: '1.0.0',
                  applicationIcon: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  ),
                  children: const [
                    SizedBox(height: 12),
                    Text(
                      'Kos Finance adalah aplikasi manajemen keuangan cerdas untuk mahasiswa dan anak kos. Mengelola saldo, pengeluaran bulanan, target budget, dan pengingat tagihan kos.',
                    ),
                  ],
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Logout',
              color: Colors.red,
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
