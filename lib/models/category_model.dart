class Category {
  final int id;
  final String name;
  final String icon;
  final String type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
    };
  }
}
