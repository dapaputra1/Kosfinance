import 'package:flutter/material.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: transaction.type == TransactionType.income
            ? Colors.green.shade100
            : Colors.red.shade100,
        child: Icon(
          transaction.type == TransactionType.income
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          color: transaction.type == TransactionType.income
              ? Colors.green
              : Colors.red,
        ),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(dateFormat.format(transaction.date)),
      trailing: Text(
        currencyFormat.format(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: transaction.type == TransactionType.income
              ? Colors.green
              : Colors.red,
        ),
      ),
      onTap: onEdit,
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onDelete();
                  Navigator.of(context).pop();
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}
