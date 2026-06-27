import 'package:hive/hive.dart';
import 'package:spendly/models/profile.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 4)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? legacyUserId;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String displayName;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final bool migrationCompleted;

  ProfileModel({
    required this.id,
    this.legacyUserId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.migrationCompleted,
  });

  factory ProfileModel.fromDomain(Profile profile) {
    return ProfileModel(
      id: profile.id,
      legacyUserId: profile.legacyUserId,
      email: profile.email,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      migrationCompleted: profile.migrationCompleted,
    );
  }

  Profile toDomain() {
    return Profile(
      id: id,
      legacyUserId: legacyUserId,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      migrationCompleted: migrationCompleted,
    );
  }
}
