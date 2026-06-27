import 'package:hive/hive.dart';
import 'package:spendly/models/family_member.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: 2)
class FamilyMemberModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String familyId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String role;

  @HiveField(4)
  final DateTime joinedAt;

  @HiveField(5)
  final String displayName;

  FamilyMemberModel({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.displayName,
  });

  factory FamilyMemberModel.fromDomain(FamilyMember member) {
    return FamilyMemberModel(
      id: member.id,
      familyId: member.familyId,
      userId: member.userId,
      role: member.role,
      joinedAt: member.joinedAt,
      displayName: member.displayName,
    );
  }

  FamilyMember toDomain() {
    return FamilyMember(
      id: id,
      familyId: familyId,
      userId: userId,
      role: role,
      joinedAt: joinedAt,
      displayName: displayName,
    );
  }
}
