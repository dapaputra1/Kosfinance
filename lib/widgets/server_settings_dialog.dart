import 'package:flutter/material.dart';
import 'package:kos_finance_app/services/api_service.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:kos_finance_app/widgets/animated_popup.dart';

void showServerSettingsDialog(BuildContext context) {
  final urlController = TextEditingController(text: ApiService.baseUrl);

  showAnimatedPopup(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text(
            'Pengaturan Server API',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sesuaikan URL server backend dengan target platform tempat aplikasi dijalankan:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Base URL Backend API',
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Preset Cepat:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.wifi_rounded, size: 16, color: AppColors.primary),
                label: const Text('WiFi HP Fisik (192.168.110.102)'),
                labelStyle: const TextStyle(fontSize: 12),
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  urlController.text = 'http://192.168.110.102:3000/api';
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.sageDark),
                label: const Text('Android Emulator (10.0.2.2)'),
                labelStyle: const TextStyle(fontSize: 12),
                backgroundColor: AppColors.sageLight,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  urlController.text = 'http://10.0.2.2:3000/api';
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.laptop_rounded, size: 16, color: AppColors.primary),
                label: const Text('Localhost (Chrome/Mac)'),
                labelStyle: const TextStyle(fontSize: 12),
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
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
                    behavior: SnackBarBehavior.floating,
                    content: Text('Server API diubah ke: $newUrl'),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
