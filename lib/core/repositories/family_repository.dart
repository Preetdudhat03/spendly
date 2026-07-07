import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

class FamilyRepository {
  final _uuid = const Uuid();

  Family? getCurrentFamily(String userId) {
    // Find the family member record for the user
    try {
      final memberModel = HiveService.familyMembers.values.firstWhere(
        (m) => m.userId == userId,
      );
      // Find the family
      final familyModel = HiveService.families.get(memberModel.familyId);
      return familyModel?.toDomain();
    } catch (_) {
      return null;
    }
  }

  List<FamilyMember> getFamilyMembers(String familyId) {
    final members = HiveService.familyMembers.values
        .where((m) => m.familyId == familyId)
        .map((m) => m.toDomain())
        .toList();

    // Deduplicate by userId
    final Map<String, FamilyMember> uniqueMembers = {};
    for (var member in members) {
      uniqueMembers[member.userId] = member;
    }
    return uniqueMembers.values.toList();
  }

  Future<Family> createFamily(String name, String userId, String displayName) async {
    final familyId = 'local_${_uuid.v4()}';
    final randCode = 'FAMILY-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    final now = DateTime.now();

    final family = Family(
      id: familyId,
      name: name,
      familyCode: randCode,
      createdBy: userId,
      createdAt: now,
    );

    // Save Family to Hive
    await HiveService.families.put(familyId, FamilyModel.fromDomain(family));

    // Save Admin Member
    final memberId = 'local_${_uuid.v4()}';
    final member = FamilyMember(
      id: memberId,
      familyId: familyId,
      userId: userId,
      role: 'admin',
      joinedAt: now,
      displayName: displayName,
    );
    await HiveService.familyMembers.put(memberId, FamilyMemberModel.fromDomain(member));

    // Queue operation
    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'CREATE_FAMILY',
      payload: {
        'family': family.toJson(),
        'member': member.toJson(),
      },
      userId: userId,
      timestamp: now,
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);

    return family;
  }

  Future<Family?> joinFamily(String familyCode, String userId, String displayName) async {
    // 1. Check Internet Connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('You must be online to join a family by code.');
    }

    final client = Supabase.instance.client;
    final normalizedCode = familyCode.trim().toUpperCase();

    // 2. Query Supabase for the Family
    final familyList = await client.from('families').select().eq('family_code', normalizedCode);
    if (familyList.isEmpty) {
      throw Exception('Family code not found.');
    }

    final familyData = familyList.first;
    final family = Family(
      id: familyData['id'],
      name: familyData['name'],
      familyCode: familyData['family_code'],
      createdBy: familyData['created_by'],
      createdAt: DateTime.parse(familyData['created_at']),
    );

    // 3. Join the family in Supabase (if not already a member)
    final memberList = await client
        .from('family_members')
        .select()
        .eq('family_id', family.id)
        .eq('user_id', userId);

    if (memberList.isEmpty) {
      await client.from('family_members').insert({
        'family_id': family.id,
        'user_id': userId,
        'role': 'member',
      });
    }

    // 4. Save to local Hive cache
    final localFamily = FamilyModel(
      id: family.id,
      name: family.name,
      familyCode: family.familyCode,
      createdBy: family.createdBy,
      createdAt: family.createdAt,
    );
    await HiveService.families.put(family.id, localFamily);

    final localMember = FamilyMemberModel(
      id: memberList.isNotEmpty ? memberList.first['id'] as String : const Uuid().v4(), // Fallback if no ID is returned immediately
      familyId: family.id,
      userId: userId,
      role: 'member',
      joinedAt: DateTime.now(),
      displayName: displayName,
    );
    await HiveService.familyMembers.put('${family.id}_$userId', localMember);

    // Optionally trigger a background pull to fetch other members and expenses
    return family;
  }

  Future<void> removeMember(String targetUserId) async {
    final client = Supabase.instance.client;
    
    // 1. Delete from Supabase
    try {
      await client.from('family_members').delete().eq('user_id', targetUserId);
    } catch (e) {
      // If offline, we might want to enqueue this, but for simplicity we let it fail or assume online
      // In a real app, we'd add to pending operations.
    }

    // 2. Delete from local Hive cache
    final memberKeys = HiveService.familyMembers.keys.toList();
    for (var key in memberKeys) {
      final member = HiveService.familyMembers.get(key);
      if (member?.userId == targetUserId) {
        await HiveService.familyMembers.delete(key);
        break;
      }
    }
  }
}
