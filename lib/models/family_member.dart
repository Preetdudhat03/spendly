class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final String displayName; // Friendly name for UI (e.g. "Dad", "Mom", "Preet")

  FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.displayName,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: json['display_name'] as String? ?? (json['role'] == 'admin' ? 'Family Admin' : 'Family Member'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'display_name': displayName,
    };
  }

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? displayName,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMember &&
        other.id == id &&
        other.familyId == familyId &&
        other.userId == userId &&
        other.role == role &&
        other.joinedAt == joinedAt &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(id, familyId, userId, role, joinedAt, displayName);
}
