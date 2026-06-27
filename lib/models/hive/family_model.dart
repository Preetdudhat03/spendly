import 'package:hive/hive.dart';
import 'package:spendly/models/family.dart';

part 'family_model.g.dart';

@HiveType(typeId: 1)
class FamilyModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String familyCode;

  @HiveField(3)
  final String? createdBy;

  @HiveField(4)
  final DateTime createdAt;

  FamilyModel({
    required this.id,
    required this.name,
    required this.familyCode,
    this.createdBy,
    required this.createdAt,
  });

  factory FamilyModel.fromDomain(Family family) {
    return FamilyModel(
      id: family.id,
      name: family.name,
      familyCode: family.familyCode,
      createdBy: family.createdBy,
      createdAt: family.createdAt,
    );
  }

  Family toDomain() {
    return Family(
      id: id,
      name: name,
      familyCode: familyCode,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
