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

final syncStateProvider = StateProvider<bool>((ref) => false);

class SyncService {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription? _connectivitySubscription;

  SyncService(this._ref);

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // In connectivity_plus >= 6.0, onConnectivityChanged returns List<ConnectivityResult>
      final result = results.first;
      if (result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.ethernet) {
        syncNow();
      }
    });

    // Automatically trigger sync whenever a new pending operation is added
    HiveService.pendingOperations.watch().listen((event) {
      if (_ref.read(syncStateProvider)) return; // Ignore local changes caused by sync process
      // Small delay to allow multiple rapid operations to batch together
      Future.delayed(const Duration(milliseconds: 500), () {
        syncNow();
      });
    });

    // Only run initial sync if native user is already authenticated
    if (_client.auth.currentUser != null) {
      debugPrint('--- CURRENT USER ---');
      debugPrint(_client.auth.currentUser!.id);
      debugPrint('--- PROFILES DUMP ---');
      for (var p in HiveService.profiles.values) {
        debugPrint('Profile: ${p.id}, name: ${p.displayName}, email: ${p.email}');
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
  }

  Future<void> syncNow() async {
    if (_ref.read(syncStateProvider)) return;

    // Guard: Only sync if native user is logged in
    final nativeUser = _client.auth.currentUser;
    if (nativeUser == null) {
      debugPrint('SyncService: Skipping sync as native user is not logged in.');
      return;
    }

    _ref.read(syncStateProvider.notifier).state = true;
    
    try {
      debugPrint('SyncService: Starting synchronization');
      await _pushPendingOperations();
      await _pullLatestData();
      debugPrint('SyncService: Synchronization complete');
    } catch (e) {
      debugPrint('SyncService: Synchronization failed: $e');
    } finally {
      _ref.read(syncStateProvider.notifier).state = false;
    }
  }

  Future<void> _pushPendingOperations() async {
    final ops = HiveService.pendingOperations.values
        .where((op) => op.syncStatus != 'SYNCING' && op.retryCount < 3)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ops.isEmpty) return;

    for (final op in ops) {
      op.syncStatus = 'SYNCING';
      await op.save();

      try {
        // Auto-heal malformed legacy payloads
        if (op.type == 'CREATE_FAMILY') {
          final familyPayload = op.payload['family'];
          final memberPayload = op.payload['member'];
          if (familyPayload['created_by'] != null && familyPayload['created_by'].toString().startsWith('user_')) {
            familyPayload['created_by'] = op.userId;
            memberPayload['user_id'] = op.userId;
            op.payload['family'] = familyPayload;
            op.payload['member'] = memberPayload;
            await op.save();
          }
        }

        await _processOperation(op);
        
        // On success, remove from queue
        await op.delete();
      } catch (e) {
        op.syncStatus = 'FAILED';
        op.lastError = e.toString();
        op.retryCount += 1;
        await op.save();
        debugPrint('SyncService: Failed to process operation ${op.id}: $e');
      }
    }
  }

  Future<void> _processOperation(PendingOperationModel op) async {
    switch (op.type) {
      case 'ADD_EXPENSE':
        final payload = op.payload;
        final tempId = payload['id'] as String;
        // Check if we already synced this by chance (e.g. if the local ID was already replaced)
        final localExpense = HiveService.expenses.get(tempId);
        
        // To Supabase
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

        // Update local database if it still exists with tempId
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

        // Propagate the new ID to any pending update/delete operations
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
          debugPrint('SyncService: UPDATE_EXPENSE failed (0 rows) for id ${payload['id']} - Check RLS or if ID exists.');
          // Don't throw if it doesn't exist, just drop it so we don't get stuck in a loop forever
        }
        break;

      case 'DELETE_EXPENSE':
        final id = op.payload['id'];
        if (!(id as String).startsWith('local_')) {
          final deleteResponse = await _client.from('expenses').delete().eq('id', id).select();
          if (deleteResponse.isEmpty) {
             debugPrint('SyncService: DELETE_EXPENSE failed (0 rows) for id $id - Check RLS or if ID exists.');
          }
        } else {
          // If it's a local_ ID, it means the ADD_EXPENSE might still be pending. We should remove the ADD_EXPENSE.
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
        
        // Update local family ID
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

        // Insert admin member
        await _client.from('family_members').insert({
          'family_id': newFamilyId,
          'user_id': memberPayload['user_id'],
          'role': memberPayload['role'],
        });

        // Auto-heal any pending operations that were referencing this local family ID
        for (var pendingOp in HiveService.pendingOperations.values) {
          if (pendingOp.payload is Map && pendingOp.payload['family_id'] == tempFamilyId) {
            pendingOp.payload['family_id'] = newFamilyId;
            await pendingOp.save();
          }
        }
        
        // Instead of replacing the member local ID properly, we will just rely on the upcoming pull to sync it
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

    // Get current family
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

    // Pull Members
    final membersList = await _client.from('family_members').select().eq('family_id', familyId);
    
    // Create map for display names
    final userIds = membersList.map((m) => m['user_id'] as String).toList();
    final Map<String, String> nameCache = {};
    if (userIds.isNotEmpty) {
      final profiles = await _client.from('profiles').select('id, display_name').inFilter('id', userIds);
      for (var p in profiles) {
        nameCache[p['id']] = p['display_name'] as String? ?? 'Family Member';
      }
    }

    final remoteMemberIds = membersList.map((m) => m['id'] as String).toSet();
    for (var m in membersList) {
      final mUserId = m['user_id'];
      await HiveService.familyMembers.put(m['id'], FamilyMemberModel(
        id: m['id'],
        familyId: m['family_id'],
        userId: mUserId,
        role: m['role'],
        joinedAt: DateTime.parse(m['joined_at']),
        displayName: nameCache[mUserId] ?? 'Family Member',
      ));
    }
    // Reconcile: delete local members that were removed on server
    final localMemberIds = HiveService.familyMembers.keys.cast<String>().toList();
    for (final id in localMemberIds) {
      final m = HiveService.familyMembers.get(id);
      if (m != null && m.familyId == familyId && !remoteMemberIds.contains(id) && !id.startsWith('local_')) {
        await HiveService.familyMembers.delete(id);
      }
    }

    // Pull Budgets
    final budgetsList = await _client.from('budgets').select().eq('family_id', familyId);
    final remoteBudgetIds = budgetsList.map((b) => b['id'] as String).toSet();
    for (var b in budgetsList) {
      await HiveService.budgets.put(b['id'], BudgetModel(
        id: b['id'],
        familyId: b['family_id'],
        monthlyBudget: (b['monthly_budget'] as num).toDouble(),
        month: b['month'],
        year: b['year'],
      ));
    }
    // Reconcile: delete local budgets that were removed on server
    final localBudgetIds = HiveService.budgets.keys.cast<String>().toList();
    for (final id in localBudgetIds) {
      final b = HiveService.budgets.get(id);
      if (b != null && b.familyId == familyId && !remoteBudgetIds.contains(id) && !id.startsWith('local_')) {
        await HiveService.budgets.delete(id);
      }
    }

    // Pull Expenses
    final expensesList = await _client.from('expenses').select().eq('family_id', familyId);
    final remoteExpenseIds = expensesList.map((e) => e['id'] as String).toSet();
    for (var e in expensesList) {
      // Check if we shouldn't overwrite if there's a pending operation for this
      final hasPendingOps = HiveService.pendingOperations.values.any((op) {
        return op.type == 'UPDATE_EXPENSE' && op.payload['id'] == e['id'];
      });

      if (!hasPendingOps) {
        final createdBy = e['created_by'];
        await HiveService.expenses.put(e['id'], ExpenseModel(
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
        ));
      }
    }
    // Reconcile: delete local expenses that were removed on server
    final localExpenseIds = HiveService.expenses.keys.cast<String>().toList();
    for (final id in localExpenseIds) {
      final e = HiveService.expenses.get(id);
      if (e != null && e.familyId == familyId && !remoteExpenseIds.contains(id) && !id.startsWith('local_')) {
        await HiveService.expenses.delete(id);
      }
    }

    // Update sync timestamp
    final syncMeta = SyncMetadataModel(
      key: 'last_sync_timestamp',
      value: DateTime.now(),
    );
    await HiveService.syncMetadata.put('last_sync_timestamp', syncMeta);
  }

  /// Merges guest/sandbox data into the new Supabase cloud account by replacing
  /// the old local guest IDs with the new real user ID and queueing them for sync.
  Future<void> mergeLocalDataToCloud(String newUserId) async {
    debugPrint('SyncService: Merging local sandbox data for new user $newUserId');

    // 1. Identify guest data (any data created by a 'user_' prefixed ID)
    final strandedFamilies = HiveService.families.values.where((f) => f.createdBy?.startsWith('user_') ?? false).toList();
    
    if (strandedFamilies.isEmpty) {
       debugPrint('SyncService: No sandbox data found to merge. Triggering pull instead.');
       syncNow();
       return;
    }

    for (final family in strandedFamilies) {
      final oldUserId = family.createdBy;
      final updatedFamily = family.toDomain().copyWith(createdBy: newUserId);
      
      final oldMembers = HiveService.familyMembers.values.where((m) => m.familyId == family.id && m.userId == oldUserId).toList();
      if (oldMembers.isNotEmpty) {
         final updatedMember = oldMembers.first.toDomain().copyWith(userId: newUserId);
         final opId = 'local_${DateTime.now().millisecondsSinceEpoch}_fam_${family.id}';
         final op = PendingOperationModel(
           id: opId,
           type: 'CREATE_FAMILY',
           payload: {
             'family': updatedFamily.toJson(),
             'member': updatedMember.toJson(),
           },
           userId: newUserId,
           timestamp: DateTime.now(),
         );
         await HiveService.pendingOperations.put(op.id, op);
      }
      
      // Expenses
      final oldExpenses = HiveService.expenses.values.where((e) => e.familyId == family.id).toList();
      for (var expense in oldExpenses) {
        if (expense.createdBy.startsWith('user_')) {
          final updatedExpense = ExpenseModel(
            id: expense.id,
            familyId: expense.familyId,
            createdBy: newUserId,
            amount: expense.amount,
            category: expense.category,
            description: expense.description,
            paymentMethod: expense.paymentMethod,
            expenseDate: expense.expenseDate,
            createdAt: expense.createdAt,
            createdByName: expense.createdByName,
          );
          final opId = 'local_${DateTime.now().millisecondsSinceEpoch}_${expense.id}';
          final op = PendingOperationModel(
            id: opId,
            type: 'ADD_EXPENSE',
            payload: updatedExpense.toDomain().toJson(),
            userId: newUserId,
            timestamp: DateTime.now(),
          );
          await HiveService.pendingOperations.put(op.id, op);
        }
      }
      
      // Budgets
      final oldBudgets = HiveService.budgets.values.where((b) => b.familyId == family.id).toList();
      for (var budget in oldBudgets) {
        final opId = 'local_${DateTime.now().millisecondsSinceEpoch}_budget_${budget.id}';
        final op = PendingOperationModel(
          id: opId,
          type: 'SET_BUDGET',
          payload: budget.toDomain().toJson(),
          userId: newUserId,
          timestamp: DateTime.now(),
        );
        await HiveService.pendingOperations.put(op.id, op);
      }
      
      // IMPORTANT: Update local models so they don't get merged again!
      await HiveService.families.put(family.id, FamilyModel.fromDomain(updatedFamily));
      if (oldMembers.isNotEmpty) {
        await HiveService.familyMembers.put(oldMembers.first.id, FamilyMemberModel.fromDomain(oldMembers.first.toDomain().copyWith(userId: newUserId)));
      }
      for (var expense in oldExpenses) {
        if (expense.createdBy.startsWith('user_')) {
           final updatedEx = expense.toDomain().copyWith(createdBy: newUserId);
           await HiveService.expenses.put(expense.id, ExpenseModel.fromDomain(updatedEx));
        }
      }
    }

    // 5. Cleanup
    await HiveService.settings.put('active_user_id', newUserId);
    debugPrint('SyncService: Sandbox data queued for upload. Triggering sync...');
    
    // 6. Trigger background sync
    syncNow();
  }
}
