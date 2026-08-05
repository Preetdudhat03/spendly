import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/profile.dart';
import 'package:spendly/models/hive/profile_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  final _uuid = const Uuid();

  Profile? getProfile(String userId) {
    final model = HiveService.profiles.get(userId);
    return model?.toDomain();
  }

  Future<void> saveProfile(Profile profile) async {
    await HiveService.profiles.put(profile.id, ProfileModel.fromDomain(profile));
  }

  Future<void> updateDisplayName(String userId, String newName) async {
    final profile = getProfile(userId);
    if (profile != null) {
      final updated = profile.copyWith(displayName: newName);
      await saveProfile(updated);

      // Update in family members if exists
      final members = HiveService.familyMembers.values.where((m) => m.userId == userId).toList();
      for (var m in members) {
        final newMember = m.toDomain().copyWith(displayName: newName);
        await HiveService.familyMembers.put(m.id, FamilyMemberModel.fromDomain(newMember));
      }

      // Update in expenses
      final expenses = HiveService.expenses.values.where((e) => e.createdBy == userId).toList();
      for (var e in expenses) {
        final newExpense = e.toDomain().copyWith(createdByName: newName);
        await HiveService.expenses.put(e.id, ExpenseModel.fromDomain(newExpense));
      }
    }

    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'UPDATE_PROFILE',
      payload: {'display_name': newName},
      userId: userId,
      timestamp: DateTime.now(),
      deviceId: HiveService.deviceId,
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);
  }
}
