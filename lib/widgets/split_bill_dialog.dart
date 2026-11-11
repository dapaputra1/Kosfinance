import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/providers/auth_provider.dart';
import 'package:kos_finance_app/providers/transaction_provider.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:kos_finance_app/widgets/animated_popup.dart';

void showSplitBillDialog(BuildContext context) {
  showAnimatedPopup(
    context: context,
    builder: (context) => const _SplitBillDialogContent(),
  );
}

class _SplitBillDialogContent extends StatefulWidget {
  const _SplitBillDialogContent();

  @override
  State<_SplitBillDialogContent> createState() => _SplitBillDialogContentState();
}

class _SplitBillDialogContentState extends State<_SplitBillDialogContent> {
  final _titleController = TextEditingController(text: 'Patungan Makan / Kos');
  final _amountController = TextEditingController();
  final _extraController = TextEditingController();
  final _discountController = TextEditingController();
  int _peopleCount = 2;
  bool _roundUp = true; // Round up to nearest Rp 1000 for ease of transfer

  double get _totalBill =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
  double get _extraCost =>
      double.tryParse(_extraController.text.replaceAll(',', '').trim()) ?? 0.0;
  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '').trim()) ?? 0.0;

  double get _netTotal => (_totalBill + _extraCost - _discount).clamp(0.0, double.infinity);

  double get _perPerson {
    if (_peopleCount <= 0 || _netTotal <= 0) return 0.0;
    final raw = _netTotal / _peopleCount;
    if (_roundUp) {
      return (raw / 1000).ceil() * 1000.0;
    }
    return raw;
  }

  void _copyToWhatsApp() {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final title = _titleController.text.trim().isEmpty ? 'Patungan Kos' : _titleController.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('🧾 *RINCIAN PATUNGAN: $title*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👥 Jumlah Orang : $_peopleCount Orang');
    buffer.writeln('💰 Total Tagihan: ${currency.format(_netTotal)}');
    if (_extraCost > 0) buffer.writeln('📦 Ongkir/Pajak : +${currency.format(_extraCost)}');
    if (_discount > 0) buffer.writeln('🏷️ Diskon/Promo : -${currency.format(_discount)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 *PER ORANG: ${currency.format(_perPerson)}*');
    if (_roundUp && (_perPerson * _peopleCount) > _netTotal) {
      buffer.writeln('*(Dibulatkan ke ribuan terdekat agar transfer mudah)*');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Mohon transfer ke rekening / e-wallet ya kawan-kawan! 🙏');
    buffer.writeln('Dicatat via Kos Finance');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Pesan patungan disalin! Siap kirim ke grup WhatsApp.')),
          ],
        ),
        backgroundColor: AppColors.income,
      ),
    );
  }

  Future<void> _recordMyShare() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (authProvider.user == null || _perPerson <= 0) return;

    final expenseCategories = transactionProvider.getCategoriesByType('expense');
    int categoryId = 1;
    if (expenseCategories.isNotEmpty) {
      final match = expenseCategories.firstWhere(
        (c) =>
            c.name.toLowerCase().contains('makan') ||
            c.name.toLowerCase().contains('food') ||
            c.name.toLowerCase().contains('util') ||
            c.name.toLowerCase().contains('kos'),
        orElse: () => expenseCategories.first,
      );
      categoryId = match.id;
    }

    final tx = Transaction(
      userId: authProvider.user!.id,
      title: 'Patungan: ${_titleController.text.trim()}',
      amount: _perPerson,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: categoryId,
      note: 'Bagian saya dari total patungan $_peopleCount orang',
    );

    final success = await transactionProvider.addTransaction(tx, authProvider.user!.token);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text('Pengeluaran bagianmu (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_perPerson)}) berhasil dicatat!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _extraController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalkulator Patungan Kos',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Bagi tagihan makan / listrik / WiFi',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Keperluan',
                  prefixIcon: const Icon(Icons.receipt_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Total bill input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Total Tagihan (Rp)',
                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // People count stepper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.group_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Jumlah Orang:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: _peopleCount > 1 ? AppColors.primary : AppColors.textMuted,
                          onPressed: _peopleCount > 1
                              ? () => setState(() => _peopleCount--)
                              : null,
                        ),
                        Text(
                          '$_peopleCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: AppColors.primary,
                          onPressed: () => setState(() => _peopleCount++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Extra & Discount Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _extraController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Ongkir / Pajak (+)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Diskon/Promo (-)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Round-up checkbox
              InkWell(
                onTap: () => setState(() => _roundUp = !_roundUp),
                child: Row(
                  children: [
                    Checkbox(
                      value: _roundUp,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _roundUp = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'Bulatkan ke atas ke Rp 1.000 terdekat (mudah transfer)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Result Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Biaya Per Orang',
                      style: TextStyle(color: Color(0xFFE2ECE0), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(_perPerson),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Bersih: ${currency.format(_netTotal)} dibagi $_peopleCount orang',
                      style: const TextStyle(color: Color(0xFFD0DFCE), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _perPerson > 0 ? _copyToWhatsApp : null,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Salin Rincian'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _perPerson > 0 ? _recordMyShare : null,
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Catat Bagianku'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
