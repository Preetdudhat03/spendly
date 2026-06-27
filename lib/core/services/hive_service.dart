import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/budget_model.dart';
import 'package:spendly/models/hive/profile_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';
import 'package:spendly/models/hive/sync_metadata_model.dart';

class HiveService {
  static const String profilesBox = 'profiles';
  static const String familiesBox = 'families';
  static const String familyMembersBox = 'family_members';
  static const String expensesBox = 'expenses';
  static const String budgetsBox = 'budgets';
  static const String settingsBox = 'settings';
  static const String pendingOperationsBox = 'pending_operations';
  static const String syncMetadataBox = 'sync_metadata';
  static const String analyticsCacheBox = 'analytics_cache';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FamilyModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FamilyMemberModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BudgetModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProfileModelAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PendingOperationModelAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(SyncMetadataModelAdapter());

    // Open Boxes
    await Future.wait([
      Hive.openBox<ProfileModel>(profilesBox),
      Hive.openBox<FamilyModel>(familiesBox),
      Hive.openBox<FamilyMemberModel>(familyMembersBox),
      Hive.openBox<ExpenseModel>(expensesBox),
      Hive.openBox<BudgetModel>(budgetsBox),
      Hive.openBox<dynamic>(settingsBox),
      Hive.openBox<PendingOperationModel>(pendingOperationsBox),
      Hive.openBox<SyncMetadataModel>(syncMetadataBox),
      Hive.openBox<dynamic>(analyticsCacheBox),
    ]);
    
    debugPrint('Hive successfully initialized and all boxes opened.');
  }

  // Getters for boxes
  static Box<ProfileModel> get profiles => Hive.box<ProfileModel>(profilesBox);
  static Box<FamilyModel> get families => Hive.box<FamilyModel>(familiesBox);
  static Box<FamilyMemberModel> get familyMembers => Hive.box<FamilyMemberModel>(familyMembersBox);
  static Box<ExpenseModel> get expenses => Hive.box<ExpenseModel>(expensesBox);
  static Box<BudgetModel> get budgets => Hive.box<BudgetModel>(budgetsBox);
  static Box<dynamic> get settings => Hive.box<dynamic>(settingsBox);
  static Box<PendingOperationModel> get pendingOperations => Hive.box<PendingOperationModel>(pendingOperationsBox);
  static Box<SyncMetadataModel> get syncMetadata => Hive.box<SyncMetadataModel>(syncMetadataBox);
  static Box<dynamic> get analyticsCache => Hive.box<dynamic>(analyticsCacheBox);
}
