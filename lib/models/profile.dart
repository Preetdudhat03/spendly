class Profile {
  final String id;
  final String? legacyUserId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool migrationCompleted;

  Profile({
    required this.id,
    this.legacyUserId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.migrationCompleted,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      legacyUserId: json['legacy_user_id'] as String?,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      migrationCompleted: json['migration_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'legacy_user_id': legacyUserId,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'migration_completed': migrationCompleted,
    };
  }

  Profile copyWith({
    String? id,
    String? legacyUserId,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? migrationCompleted,
  }) {
    return Profile(
      id: id ?? this.id,
      legacyUserId: legacyUserId ?? this.legacyUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      migrationCompleted: migrationCompleted ?? this.migrationCompleted,
    );
  }
}
