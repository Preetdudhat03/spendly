import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/hive/profile_model.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/budget_model.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/budget.dart';

class MigrationService {
  static const String _migrationKey = 'is_migrated_to_hive';

  static Future<void> runMigration(SharedPreferences prefs) async {
    final bool isMigrated = HiveService.settings.get(_migrationKey, defaultValue: false);
    if (isMigrated) {
      debugPrint('MigrationService: Already migrated to Hive.');
      return;
    }

    debugPrint('MigrationService: Starting migration to Hive...');

    try {
      // 1. Migrate Supabase session (if it exists)
      final supaUserId = prefs.getString('supabase_user_id');
      final supaEmail = prefs.getString('supabase_user_email');
      final supaName = prefs.getString('supabase_user_display_name');

      if (supaUserId != null && supaEmail != null) {
        final profile = ProfileModel(
          id: supaUserId,
          email: supaEmail,
          displayName: supaName ?? 'User',
          migrationCompleted: true,
        );
        await HiveService.profiles.put(supaUserId, profile);
        // We'll also store the active user id in settings for easy access
        await HiveService.settings.put('active_user_id', supaUserId);
      }

      // 2. Migrate Mock Data (if they were using local mode)
      
      // Families
      final familiesRaw = prefs.getStringList('mock_families') ?? [];
      for (var fStr in familiesRaw) {
        final f = Family.fromJson(json.decode(fStr));
        await HiveService.families.put(f.id, FamilyModel.fromDomain(f));
      }

      // Members
      final membersRaw = prefs.getStringList('mock_members') ?? [];
      for (var mStr in membersRaw) {
        final m = FamilyMember.fromJson(json.decode(mStr));
        await HiveService.familyMembers.put(m.id, FamilyMemberModel.fromDomain(m));
      }

      // Expenses
      final expensesRaw = prefs.getStringList('mock_expenses') ?? [];
      for (var eStr in expensesRaw) {
        final e = Expense.fromJson(json.decode(eStr));
        await HiveService.expenses.put(e.id, ExpenseModel.fromDomain(e));
      }

      // Budgets
      final budgetsRaw = prefs.getStringList('mock_budgets') ?? [];
      for (var bStr in budgetsRaw) {
        final b = Budget.fromJson(json.decode(bStr));
        await HiveService.budgets.put(b.id, BudgetModel.fromDomain(b));
      }

      // We won't migrate mock users to profiles because Supabase profile should be used if online.
      // But if there's no Supabase session, we should migrate the mock session so they stay logged in offline.
      if (supaUserId == null) {
        final mockCurrentUserId = prefs.getString('mock_current_user_id');
        if (mockCurrentUserId != null) {
           await HiveService.settings.put('active_user_id', mockCurrentUserId);
        }
      }

      // 3. Keep SharedPreferences for blacklisted suggestions (or other lightweight things)
      // We don't delete everything, we just mark as migrated.
      await HiveService.settings.put(_migrationKey, true);

      debugPrint('MigrationService: Migration to Hive completed successfully.');
    } catch (e) {
      debugPrint('MigrationService: Error during migration: $e');
    }
  }
}
