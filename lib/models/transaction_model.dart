enum TransactionType { income, expense }

class Transaction {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final int categoryId;
  final String? note;
  final String? categoryName;
  final String? categoryIcon;

  Transaction({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    this.note,
    this.categoryName,
    this.categoryIcon,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: json['category_id'],
      note: json['note'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category_id': categoryId,
      'note': note,
      'category_name': categoryName,
      'category_icon': categoryIcon,
    };
  }

  Transaction copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    int? categoryId,
    String? note,
    String? categoryName,
    String? categoryIcon,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }
}
