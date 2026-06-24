class Category {
  final String id;
  final String? familyId; // Null for system/default categories
  final String name;
  final String icon; // Icon name string, e.g. "fastfood", "directions_car", etc.

  Category({
    required this.id,
    this.familyId,
    required this.name,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'icon': icon,
    };
  }

  Category copyWith({
    String? id,
    String? familyId,
    String? name,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
