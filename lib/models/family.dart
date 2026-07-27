class Family {
  final String id;
  final String name;
  final String familyCode;
  final String? createdBy;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    required this.familyCode,
    this.createdBy,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      familyCode: json['family_code'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'family_code': familyCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Family copyWith({
    String? id,
    String? name,
    String? familyCode,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      familyCode: familyCode ?? this.familyCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Family &&
        other.id == id &&
        other.name == name &&
        other.familyCode == familyCode &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, familyCode, createdBy, createdAt);
}
