import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/budget_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';
import 'package:spendly/models/hive/sync_metadata_model.dart';
import 'package:spendly/core/providers/state_providers.dart';

final syncStateProvider = StateProvider<bool>((ref) => false);

class SyncService {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription? _connectivitySubscription;
  Timer? _syncDebounceTimer;
  DateTime? _lastSyncFailureTime;
  bool _isSyncing = false;

  SyncService(this._ref);

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.first;
      if (result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.ethernet) {
        _lastSyncFailureTime = null; // Reset failure timer on network change
        syncNow();
      }
    });

    // Automatically trigger sync whenever a new pending operation is added
    HiveService.pendingOperations.watch().listen((event) {
      if (event.deleted) return; // Ignore deletion events
      if (_isSyncing || _ref.read(syncStateProvider)) return; // Ignore local changes during sync

      // Cool-down: If last sync failed within 15s due to network issue, back off
      if (_lastSyncFailureTime != null &&
          DateTime.now().difference(_lastSyncFailureTime!) < const Duration(seconds: 15)) {
        return;
      }

      _syncDebounceTimer?.cancel();
      _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        syncNow();
      });
    });

    // Only run initial sync if native user is already authenticated
    if (_client.auth.currentUser != null) {
      debugPrint('--- CURRENT USER ---');
      debugPrint(_client.auth.currentUser!.id);
      debugPrint('--- PENDING OPS DUMP ---');
      for (var op in HiveService.pendingOperations.values) {
        debugPrint('Op: ${op.id}, type: ${op.type}, userId: ${op.userId}, retryCount: ${op.retryCount}');
      }
      debugPrint('-----------------');

      Future.microtask(() {
        final hasStrandedData = HiveService.families.values.any((f) => f.createdBy?.startsWith('user_') ?? false);
        if (hasStrandedData) {
          mergeLocalDataToCloud(_client.auth.currentUser!.id);
        } else {
          syncNow();
        }
      });
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncDebounceTimer?.cancel();
  }

  bool _isNetworkError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
           str.contains('failed host lookup') ||
           str.contains('clientexception') ||
           str.contains('connection failed') ||
           str.contains('timeout');
  }

  Future<void> syncNow() async {
    if (_isSyncing || _ref.read(syncStateProvider)) return;

    // Guard: Only sync if native user is logged in
    final nativeUser = _client.auth.currentUser;
    if (nativeUser == null) {
      debugPrint('SyncService: Skipping sync as native user is not logged in.');
      return;
    }

    _isSyncing = true;
    _ref.read(syncStateProvider.notifier).state = true;
    
    try {
      debugPrint('SyncService: Starting synchronization for user ${nativeUser.id}');
      await _pushPendingOperations();
      await _pullLatestData();
      _lastSyncFailureTime = null;
      
      await HiveService.logSyncEvent('SYNC', status: 'SUCCESS', message: 'Sync complete');
      await HiveService.updateUserRegistry(
        userId: nativeUser.id,
        lastSuccessfulSync: DateTime.now(),
        expensesCount: HiveService.expenses.length,
        pendingSyncCount: HiveService.pendingOperations.length,
      );
      debugPrint('SyncService: Synchronization complete');
    } catch (e) {
      _lastSyncFailureTime = DateTime.now();
      await HiveService.logSyncEvent('SYNC', status: 'ERROR', message: e.toString());
      debugPrint('SyncService: Synchronization failed: $e');
    } finally {
      _isSyncing = false;
      _ref.read(syncStateProvider.notifier).state = false;
    }
  }

  Future<void> _pushPendingOperations() async {
    final nativeUser = _client.auth.currentUser;
    if (nativeUser == null) return;

    final ops = HiveService.pendingOperations.values
        .where((op) => op.syncStatus != 'SYNCING' && op.retryCount < 3)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ops.isEmpty) return;

    int pushedCount = 0;

    for (final op in ops) {
      // Sync Ownership Guard: Never upload an operation that does not belong to the active authenticated user
      if (op.userId != null && op.userId != nativeUser.id && !op.userId!.startsWith('user_')) {
        debugPrint('SyncService: Skipping operation ${op.id} as userId (${op.userId}) does not match authenticated user (${nativeUser.id})');
        await HiveService.logSyncEvent('PUSH_SKIPPED', status: 'WARN', message: 'User mismatch for op ${op.id}');
        continue;
      }

      op.syncStatus = 'SYNCING';
      await op.save();

      try {
        // Auto-heal malformed legacy payloads
        if (op.type == 'CREATE_FAMILY') {
          final familyPayload = op.payload['family'];
          final memberPayload = op.payload['member'];
          if (familyPayload['created_by'] != null && familyPayload['created_by'].toString().startsWith('user_')) {
            familyPayload['created_by'] = nativeUser.id;
            memberPayload['user_id'] = nativeUser.id;
            op.payload['family'] = familyPayload;
            op.payload['member'] = memberPayload;
            await op.save();
          }
        }

        await _processOperation(op);
        pushedCount++;
        
        // On success, remove from queue
        await op.delete();
      } catch (e) {
        op.syncStatus = 'FAILED';
        op.lastError = e.toString();
        op.retryCount += 1;
        await op.save();
        debugPrint('SyncService: Failed to process operation ${op.id}: $e');

        if (_isNetworkError(e)) {
          _lastSyncFailureTime = DateTime.now();
          debugPrint('SyncService: Network error detected. Aborting sync queue to prevent loop.');
          break;
        }
      }
    }

    if (pushedCount > 0) {
      await HiveService.logSyncEvent('PUSH', status: 'SUCCESS', opsPushed: pushedCount);
    }
  }

  Future<void> _processOperation(PendingOperationModel op) async {
    switch (op.type) {
      case 'ADD_EXPENSE':
        final payload = op.payload;
        final tempId = payload['id'] as String;
        final localExpense = HiveService.expenses.get(tempId);
        
        final response = await _client.from('expenses').insert({
          'family_id': payload['family_id'],
          'created_by': payload['created_by'],
          'amount': payload['amount'],
          'category': payload['category'],
          'description': payload['description'],
          'payment_method': payload['payment_method'],
          'expense_date': payload['expense_date'],
        }).select().single();

        final newId = response['id'] as String;
        final createdAt = DateTime.parse(response['created_at']);

        if (localExpense != null) {
          final updatedExpense = ExpenseModel(
            id: newId,
            familyId: localExpense.familyId,
            createdBy: localExpense.createdBy,
            amount: localExpense.amount,
            category: localExpense.category,
            description: localExpense.description,
            paymentMethod: localExpense.paymentMethod,
            expenseDate: localExpense.expenseDate,
            createdAt: createdAt,
            createdByName: localExpense.createdByName,
          );
          await HiveService.expenses.delete(tempId);
          await HiveService.expenses.put(newId, updatedExpense);
        }

        final pendingOps = HiveService.pendingOperations.values
            .where((p) => p.payload != null && p.payload['id'] == tempId);
        for (final p in pendingOps) {
          p.payload['id'] = newId;
          await p.save();
        }
        break;
      
      case 'UPDATE_EXPENSE':
        final payload = op.payload;
        final updateResponse = await _client.from('expenses').update({
          'amount': payload['amount'],
          'category': payload['category'],
          'description': payload['description'],
          'payment_method': payload['payment_method'],
          'expense_date': payload['expense_date'],
        }).eq('id', payload['id']).select();
        
        if (updateResponse.isEmpty) {
          debugPrint('SyncService: UPDATE_EXPENSE failed (0 rows) for id ${payload['id']}');
        }
        break;

      case 'DELETE_EXPENSE':
        final id = op.payload['id'];
        if (!(id as String).startsWith('local_')) {
          final deleteResponse = await _client.from('expenses').delete().eq('id', id).select();
          if (deleteResponse.isEmpty) {
             debugPrint('SyncService: DELETE_EXPENSE failed (0 rows) for id $id');
          }
        } else {
          final addOps = HiveService.pendingOperations.values
              .where((p) => p.type == 'ADD_EXPENSE' && p.payload['id'] == id);
          for (final p in addOps) {
             await p.delete();
          }
        }
        break;

      case 'CREATE_FAMILY':
        final familyPayload = op.payload['family'];
        final memberPayload = op.payload['member'];
        final tempFamilyId = familyPayload['id'] as String;
        
        final response = await _client.from('families').insert({
          'name': familyPayload['name'],
          'family_code': familyPayload['family_code'],
          'created_by': familyPayload['created_by'],
        }).select().single();
        
        final newFamilyId = response['id'] as String;
        final createdAt = DateTime.parse(response['created_at']);
        
        final localFamily = HiveService.families.get(tempFamilyId);
        if (localFamily != null) {
          final updatedFamily = FamilyModel(
            id: newFamilyId,
            name: localFamily.name,
            familyCode: localFamily.familyCode,
            createdBy: localFamily.createdBy,
            createdAt: createdAt,
          );
          await HiveService.families.delete(tempFamilyId);
          await HiveService.families.put(newFamilyId, updatedFamily);
        }

        await _client.from('family_members').insert({
          'family_id': newFamilyId,
          'user_id': memberPayload['user_id'],
          'role': memberPayload['role'],
        });

        for (var pendingOp in HiveService.pendingOperations.values) {
          if (pendingOp.payload is Map && pendingOp.payload['family_id'] == tempFamilyId) {
            pendingOp.payload['family_id'] = newFamilyId;
            await pendingOp.save();
          }
        }
        break;

      case 'SET_BUDGET':
        final payload = op.payload;
        await _client.from('budgets').upsert({
          'family_id': payload['family_id'],
          'monthly_budget': payload['monthly_budget'],
          'month': payload['month'],
          'year': payload['year'],
        }, onConflict: 'family_id, month, year');
        break;

      case 'UPDATE_PROFILE':
        final name = op.payload['display_name'];
        await _client.from('profiles').update({'display_name': name}).eq('id', op.userId!);
        break;
    }
  }

  Future<void> _pullLatestData() async {
    final nativeUser = _client.auth.currentUser;
    if (nativeUser == null) return;
    final userId = nativeUser.id;

    final memberData = await _client.from('family_members').select().eq('user_id', userId).maybeSingle();
    if (memberData == null) return;

    final familyId = memberData['family_id'] as String;

    // Pull Family
    final familyData = await _client.from('families').select().eq('id', familyId).single();
    await HiveService.families.put(familyId, FamilyModel(
      id: familyData['id'],
      name: familyData['name'],
      familyCode: familyData['family_code'],
      createdBy: familyData['created_by'],
      createdAt: DateTime.parse(familyData['created_at']),
    ));

    // Pull Members (Batch updates into putAll)
    final membersList = await _client.from('family_members').select().eq('family_id', familyId);
    final userIds = membersList.map((m) => m['user_id'] as String).toList();
    final Map<String, String> nameCache = {};
    if (userIds.isNotEmpty) {
      final profiles = await _client.from('profiles').select('id, display_name').inFilter('id', userIds);
      for (var p in profiles) {
        nameCache[p['id']] = p['display_name'] as String? ?? 'Family Member';
      }
    }

    final remoteMemberIds = membersList.map((m) => m['id'] as String).toSet();
    final Map<String, FamilyMemberModel> memberUpdates = {};
    for (var m in membersList) {
      final mUserId = m['user_id'];
      memberUpdates[m['id']] = FamilyMemberModel(
        id: m['id'],
        familyId: m['family_id'],
        userId: mUserId,
        role: m['role'],
        joinedAt: DateTime.parse(m['joined_at']),
        displayName: nameCache[mUserId] ?? 'Family Member',
      );
    }
    if (memberUpdates.isNotEmpty) {
      await HiveService.familyMembers.putAll(memberUpdates);
    }

    final localMemberIds = HiveService.familyMembers.keys.cast<String>().toList();
    final memberDeletions = <String>[];
    for (final id in localMemberIds) {
      final m = HiveService.familyMembers.get(id);
      if (m != null && m.familyId == familyId && !remoteMemberIds.contains(id) && !id.startsWith('local_')) {
        memberDeletions.add(id);
      }
    }
    if (memberDeletions.isNotEmpty) {
      await HiveService.familyMembers.deleteAll(memberDeletions);
    }

    // Pull Budgets (Batch updates into putAll)
    final budgetsList = await _client.from('budgets').select().eq('family_id', familyId);
    final remoteBudgetIds = budgetsList.map((b) => b['id'] as String).toSet();
    final Map<String, BudgetModel> budgetUpdates = {};
    for (var b in budgetsList) {
      budgetUpdates[b['id']] = BudgetModel(
        id: b['id'],
        familyId: b['family_id'],
        monthlyBudget: (b['monthly_budget'] as num).toDouble(),
        month: b['month'],
        year: b['year'],
      );
    }
    if (budgetUpdates.isNotEmpty) {
      await HiveService.budgets.putAll(budgetUpdates);
    }

    final localBudgetIds = HiveService.budgets.keys.cast<String>().toList();
    final budgetDeletions = <String>[];
    for (final id in localBudgetIds) {
      final b = HiveService.budgets.get(id);
      if (b != null && b.familyId == familyId && !remoteBudgetIds.contains(id) && !id.startsWith('local_')) {
        budgetDeletions.add(id);
      }
    }
    if (budgetDeletions.isNotEmpty) {
      await HiveService.budgets.deleteAll(budgetDeletions);
    }

    // Pull Expenses (Batch updates into putAll)
    final expensesList = await _client.from('expenses').select().eq('family_id', familyId);
    final remoteExpenseIds = expensesList.map((e) => e['id'] as String).toSet();
    final Map<String, ExpenseModel> expenseUpdates = {};
    for (var e in expensesList) {
      final hasPendingOps = HiveService.pendingOperations.values.any((op) {
        return op.type == 'UPDATE_EXPENSE' && op.payload['id'] == e['id'];
      });

      if (!hasPendingOps) {
        final createdBy = e['created_by'];
        expenseUpdates[e['id']] = ExpenseModel(
          id: e['id'],
          familyId: e['family_id'],
          createdBy: createdBy,
          amount: (e['amount'] as num).toDouble(),
          category: e['category'],
          description: e['description'] ?? '',
          paymentMethod: e['payment_method'] ?? 'UPI',
          expenseDate: DateTime.parse(e['expense_date']),
          createdAt: DateTime.parse(e['created_at']),
          createdByName: nameCache[createdBy] ?? 'Family Member',
        );
      }
    }
    if (expenseUpdates.isNotEmpty) {
      await HiveService.expenses.putAll(expenseUpdates);
    }

    final localExpenseIds = HiveService.expenses.keys.cast<String>().toList();
    final expenseDeletions = <String>[];
    for (final id in localExpenseIds) {
      final e = HiveService.expenses.get(id);
      if (e != null && e.familyId == familyId && !remoteExpenseIds.contains(id) && !id.startsWith('local_')) {
        expenseDeletions.add(id);
      }
    }
    if (expenseDeletions.isNotEmpty) {
      await HiveService.expenses.deleteAll(expenseDeletions);
    }

    final syncMeta = SyncMetadataModel(
      key: 'last_sync_timestamp',
      value: DateTime.now(),
    );
    await HiveService.syncMetadata.put('last_sync_timestamp', syncMeta);
    await HiveService.logSyncEvent('PULL', status: 'SUCCESS', itemsPulled: expensesList.length);
  }

  Future<void> mergeLocalDataToCloud(String newUserId) async {
    debugPrint('SyncService: Merging local guest sandbox data for new user $newUserId');
    await HiveService.updateUserRegistry(userId: newUserId, migrationState: 'IN_PROGRESS');

    // ONLY merge families that were created during an unauthenticated guest session (starting with 'user_')
    final guestFamilies = HiveService.families.values
        .where((f) => f.createdBy != null && f.createdBy!.startsWith('user_'))
        .toList();
    
    if (guestFamilies.isEmpty) {
       debugPrint('SyncService: No guest sandbox data found to merge. Triggering pull instead.');
       await HiveService.updateUserRegistry(userId: newUserId, migrationState: 'COMPLETED');
       syncNow();
       return;
    }

    bool localDataUpdated = false;

    for (final family in guestFamilies) {
      final oldUserId = family.createdBy;
      if (oldUserId == null || oldUserId.isEmpty) continue;

      // STRICT MIGRATION GUARD: NEVER call complete_user_migration for real UUIDs
      bool isRealUuid = oldUserId.length > 20 && !oldUserId.startsWith('user_');

      if (isRealUuid) {
         debugPrint('SyncService Migration Guard: Refusing to migrate real UUID $oldUserId to $newUserId');
         continue;
      }

      final updatedFamily = family.toDomain().copyWith(createdBy: newUserId);
      await HiveService.families.put(family.id, FamilyModel.fromDomain(updatedFamily));
      
      final members = HiveService.familyMembers.values.where((m) => m.familyId == family.id).toList();
      for (var m in members) {
         if (m.userId == oldUserId) {
             final updatedMember = m.toDomain().copyWith(userId: newUserId);
             await HiveService.familyMembers.put(m.id, FamilyMemberModel.fromDomain(updatedMember));
         }
      }

      final expenses = HiveService.expenses.values.where((e) => e.familyId == family.id).toList();
      for (var e in expenses) {
         if (e.createdBy == oldUserId) {
             final updatedEx = e.toDomain().copyWith(createdBy: newUserId);
             await HiveService.expenses.put(e.id, ExpenseModel.fromDomain(updatedEx));
         }
      }

      final budgets = HiveService.budgets.values.where((b) => b.familyId == family.id).toList();

      for (var op in HiveService.pendingOperations.values) {
         if (op.userId == oldUserId) {
             final updatedOp = PendingOperationModel(
                id: op.id, 
                type: op.type, 
                payload: op.payload, 
                userId: newUserId, 
                timestamp: op.timestamp,
                retryCount: op.retryCount,
                deviceId: HiveService.deviceId,
             );
             await HiveService.pendingOperations.put(op.id, updatedOp);
         }
      }

      final familyOpId = 'local_${DateTime.now().millisecondsSinceEpoch}_fam_${family.id}';
      final adminMember = HiveService.familyMembers.values.firstWhere(
         (m) => m.familyId == family.id && m.userId == newUserId, 
         orElse: () => HiveService.familyMembers.values.first,
      ).toDomain();
      
      final op = PendingOperationModel(
        id: familyOpId,
        type: 'CREATE_FAMILY',
        payload: {
          'family': updatedFamily.toJson(),
          'member': adminMember.toJson(),
        },
        userId: newUserId,
        timestamp: DateTime.now(),
        deviceId: HiveService.deviceId,
      );
      await HiveService.pendingOperations.put(op.id, op);

      for (var e in expenses) {
          if (e.createdBy == oldUserId) {
              final opId = 'local_${DateTime.now().millisecondsSinceEpoch}_${e.id}';
              final opEx = PendingOperationModel(
                id: opId,
                type: 'ADD_EXPENSE',
                payload: e.toDomain().copyWith(createdBy: newUserId).toJson(),
                userId: newUserId,
                timestamp: DateTime.now(),
                deviceId: HiveService.deviceId,
              );
              await HiveService.pendingOperations.put(opEx.id, opEx);
          }
      }

      for (var b in budgets) {
          final opId = 'local_${DateTime.now().millisecondsSinceEpoch}_budget_${b.id}';
          final opB = PendingOperationModel(
            id: opId,
            type: 'SET_BUDGET',
            payload: b.toDomain().toJson(),
            userId: newUserId,
            timestamp: DateTime.now(),
            deviceId: HiveService.deviceId,
          );
          await HiveService.pendingOperations.put(opB.id, opB);
      }

      localDataUpdated = true;
    }

    if (localDataUpdated) {
        Future.delayed(const Duration(milliseconds: 500), () {
            try {
              _ref.read(familyProvider.notifier).loadFamily();
              _ref.read(expenseProvider.notifier).loadExpenses();
            } catch (_) {}
        });
    }

    await HiveService.updateUserRegistry(userId: newUserId, migrationState: 'COMPLETED');
    await HiveService.settings.put('active_user_id', newUserId);
    debugPrint('SyncService: Guest sandbox data queued for upload. Triggering sync...');
    syncNow();
  }
}
