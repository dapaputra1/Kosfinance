import 'package:flutter/material.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RecentTransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const RecentTransactionItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM');
    final isIncome = transaction.type == TransactionType.income;
    final catName = transaction.categoryName ?? (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final catColor = AppColors.getCategoryColor(catName);
    final catIcon = AppColors.getCategoryIcon(catName);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFormat.format(transaction.date)} • $catName',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIncome ? AppColors.income : AppColors.expense,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
