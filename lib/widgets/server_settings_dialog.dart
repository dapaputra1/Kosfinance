import 'package:flutter/material.dart';
import 'package:kos_finance_app/services/api_service.dart';

void showServerSettingsDialog(BuildContext context) {
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
            'Gunakan URL server backend sesuai platform tempat aplikasi dijalankan:',
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
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.laptop, size: 16),
                label: const Text('Localhost (Chrome/Mac)'),
                onPressed: () {
                  urlController.text = 'http://localhost:3000/api';
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.android, size: 16),
                label: const Text('Android (10.0.2.2)'),
                onPressed: () {
                  urlController.text = 'http://10.0.2.2:3000/api';
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
