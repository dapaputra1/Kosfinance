class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? note;
  final String? icon;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.note,
    this.icon,
  });

  bool get isAchieved => currentAmount >= targetAmount;

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get percentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? note,
    String? icon,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      note: note ?? this.note,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'note': note,
      'icon': icon,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      icon: json['icon'] as String?,
    );
  }
}
