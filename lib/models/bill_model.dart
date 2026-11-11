class BillReminder {
  final String id;
  final String title;
  final double amount;
  final int dueDay; // 1 - 31 (Day of each month)
  final bool isPaid;
  final String? note;

  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDay,
    this.isPaid = false,
    this.note,
  });

  factory BillReminder.fromJson(Map<String, dynamic> json) {
    return BillReminder(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['dueDay'] as int,
      isPaid: json['isPaid'] as bool? ?? false,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDay': dueDay,
      'isPaid': isPaid,
      'note': note,
    };
  }

  BillReminder copyWith({
    String? id,
    String? title,
    double? amount,
    int? dueDay,
    bool? isPaid,
    String? note,
  }) {
    return BillReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      isPaid: isPaid ?? this.isPaid,
      note: note ?? this.note,
    );
  }
}
