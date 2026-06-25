import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';

class MockDbService implements DbService {
  final SharedPreferences _prefs;

  MockDbService(this._prefs) {
    _initDefaults();
  }

  // Local storage keys
  static const String _keyUsers = 'mock_users'; // map of email -> userMap
  static const String _keyCurrentUserId = 'mock_current_user_id';
  static const String _keyFamilies = 'mock_families'; // list of family JSON
  static const String _keyMembers = 'mock_members'; // list of member JSON
  static const String _keyExpenses = 'mock_expenses'; // list of expense JSON
  static const String _keyBudgets = 'mock_budgets'; // list of budget JSON

  void _initDefaults() {
    // If no families exist, we can pre-populate if needed, but let's start clean.
  }

  // --- Authentication ---

  @override
  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    if (users.containsKey(email.toLowerCase())) {
      throw Exception('User with this email already exists.');
    }

    final userId = 'user_${Random().nextInt(900000) + 100000}';
    users[email.toLowerCase()] = {
      'id': userId,
      'email': email,
      'password': CryptoUtils.hashPassword(password),
      'displayName': displayName,
    };

    await _prefs.setString(_keyUsers, json.encode(users));
    await _prefs.setString(_keyCurrentUserId, userId);
    return userId;
  }

  @override
  Future<String?> signIn({required String email, required String password}) async {
    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    final normalizedEmail = email.toLowerCase();
    final hashedPassword = CryptoUtils.hashPassword(password);
    if (!users.containsKey(normalizedEmail) || users[normalizedEmail]['password'] != hashedPassword) {
      throw Exception('Invalid email or password.');
    }

    final userId = users[normalizedEmail]['id'] as String;
    await _prefs.setString(_keyCurrentUserId, userId);
    return userId;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_keyCurrentUserId);
  }

  @override
  String? getCurrentUserId() {
    return _prefs.getString(_keyCurrentUserId);
  }

  @override
  String? getCurrentUserEmail() {
    final currentId = getCurrentUserId();
    if (currentId == null) return null;

    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    for (var u in users.values) {
      if (u['id'] == currentId) {
        return u['email'] as String;
      }
    }
    return null;
  }

  @override
  Future<String?> getCurrentUserDisplayName() async {
    final currentId = getCurrentUserId();
    if (currentId == null) return null;

    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    for (var u in users.values) {
      if (u['id'] == currentId) {
        return u['displayName'] as String;
      }
    }
    return 'User';
  }

  @override
  Future<String?> forgotPassword(String email) async {
    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);

    final normalizedEmail = email.toLowerCase().trim();
    if (!users.containsKey(normalizedEmail)) {
      throw Exception('Email not found.');
    }

    final tempPassword = 'TEMP-${Random().nextInt(9000) + 1000}';
    users[normalizedEmail]['password'] = CryptoUtils.hashPassword(tempPassword);
    await _prefs.setString(_keyUsers, json.encode(users));
    return tempPassword;
  }

  // --- Family ---

  @override
  Future<Family?> createFamily({required String name}) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Must be logged in.');

    final randCode = 'FAMILY-${Random().nextInt(9000) + 1000}';
    final familyId = 'family_${Random().nextInt(900000) + 100000}';
    final newFamily = Family(
      id: familyId,
      name: name,
      familyCode: randCode,
      createdBy: userId,
      createdAt: DateTime.now(),
    );

    // Save Family
    final familiesRaw = _prefs.getStringList(_keyFamilies) ?? [];
    familiesRaw.add(json.encode(newFamily.toJson()));
    await _prefs.setStringList(_keyFamilies, familiesRaw);

    // Get display name
    final displayName = await getCurrentUserDisplayName() ?? 'Family Admin';

    // Add Creator as Admin Member
    final memberId = 'member_${Random().nextInt(900000) + 100000}';
    final adminMember = FamilyMember(
      id: memberId,
      familyId: familyId,
      userId: userId,
      role: 'admin',
      joinedAt: DateTime.now(),
      displayName: displayName,
    );

    final membersRaw = _prefs.getStringList(_keyMembers) ?? [];
    membersRaw.add(json.encode(adminMember.toJson()));
    await _prefs.setStringList(_keyMembers, membersRaw);

    return newFamily;
  }

  @override
  Future<Family?> joinFamily({required String familyCode}) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Must be logged in.');

    // Find family by code
    final familiesRaw = _prefs.getStringList(_keyFamilies) ?? [];
    Family? targetFamily;
    for (var fStr in familiesRaw) {
      final f = Family.fromJson(json.decode(fStr));
      if (f.familyCode.toUpperCase() == familyCode.trim().toUpperCase()) {
        targetFamily = f;
        break;
      }
    }

    if (targetFamily == null) {
      throw Exception('Family code not found.');
    }

    // Check if user is already a member
    final membersRaw = _prefs.getStringList(_keyMembers) ?? [];
    for (var mStr in membersRaw) {
      final m = FamilyMember.fromJson(json.decode(mStr));
      if (m.familyId == targetFamily.id && m.userId == userId) {
        return targetFamily; // Already joined
      }
    }

    // Add as member
    final displayName = await getCurrentUserDisplayName() ?? 'Family Member';
    final memberId = 'member_${Random().nextInt(900000) + 100000}';
    final newMember = FamilyMember(
      id: memberId,
      familyId: targetFamily.id,
      userId: userId,
      role: 'member',
      joinedAt: DateTime.now(),
      displayName: displayName,
    );

    membersRaw.add(json.encode(newMember.toJson()));
    await _prefs.setStringList(_keyMembers, membersRaw);

    return targetFamily;
  }

  @override
  Future<Family?> getCurrentFamily() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final membersRaw = _prefs.getStringList(_keyMembers) ?? [];
    String? currentFamilyId;
    for (var mStr in membersRaw) {
      final m = FamilyMember.fromJson(json.decode(mStr));
      if (m.userId == userId) {
        currentFamilyId = m.familyId;
        break;
      }
    }

    if (currentFamilyId == null) return null;

    final familiesRaw = _prefs.getStringList(_keyFamilies) ?? [];
    for (var fStr in familiesRaw) {
      final f = Family.fromJson(json.decode(fStr));
      if (f.id == currentFamilyId) {
        return f;
      }
    }

    return null;
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    final family = await getCurrentFamily();
    if (family == null) return [];

    final membersRaw = _prefs.getStringList(_keyMembers) ?? [];
    final List<FamilyMember> list = [];
    for (var mStr in membersRaw) {
      final m = FamilyMember.fromJson(json.decode(mStr));
      if (m.familyId == family.id) {
        list.add(m);
      }
    }
    return list;
  }

  @override
  Future<void> updateMemberDisplayName(String name) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    // Update member's display name in registered users list
    final usersRaw = _prefs.getString(_keyUsers) ?? '{}';
    final Map<String, dynamic> users = json.decode(usersRaw);
    for (var email in users.keys) {
      if (users[email]['id'] == userId) {
        users[email]['displayName'] = name;
        break;
      }
    }
    await _prefs.setString(_keyUsers, json.encode(users));

    // Update in family members list
    final membersRaw = _prefs.getStringList(_keyMembers) ?? [];
    final List<String> updatedMembers = [];
    for (var mStr in membersRaw) {
      var m = FamilyMember.fromJson(json.decode(mStr));
      if (m.userId == userId) {
        m = m.copyWith(displayName: name);
      }
      updatedMembers.add(json.encode(m.toJson()));
    }
    await _prefs.setStringList(_keyMembers, updatedMembers);

    // Also update all expenses where they were creator to update display name
    final expensesRaw = _prefs.getStringList(_keyExpenses) ?? [];
    final List<String> updatedExpenses = [];
    for (var eStr in expensesRaw) {
      var e = Expense.fromJson(json.decode(eStr));
      if (e.createdBy == userId) {
        e = e.copyWith(createdByName: name);
      }
      updatedExpenses.add(json.encode(e.toJson()));
    }
    await _prefs.setStringList(_keyExpenses, updatedExpenses);
  }

  // --- Expenses ---

  @override
  Future<List<Expense>> getExpenses() async {
    final family = await getCurrentFamily();
    if (family == null) return [];

    final expensesRaw = _prefs.getStringList(_keyExpenses) ?? [];
    final List<Expense> list = [];
    for (var eStr in expensesRaw) {
      final e = Expense.fromJson(json.decode(eStr));
      if (e.familyId == family.id) {
        list.add(e);
      }
    }
    // Sort reverse chronological
    list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return list;
  }

  @override
  Future<Expense> addExpense({
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    final userId = getCurrentUserId();
    final family = await getCurrentFamily();
    if (userId == null || family == null) {
      throw Exception('Must be logged in and part of a family.');
    }

    final displayName = await getCurrentUserDisplayName() ?? 'Family Member';
    final expenseId = 'expense_${Random().nextInt(900000) + 100000}';

    final newExpense = Expense(
      id: expenseId,
      familyId: family.id,
      createdBy: userId,
      amount: amount,
      category: category,
      description: description,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      createdByName: displayName,
    );

    final expensesRaw = _prefs.getStringList(_keyExpenses) ?? [];
    expensesRaw.add(json.encode(newExpense.toJson()));
    await _prefs.setStringList(_keyExpenses, expensesRaw);

    return newExpense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    final expensesRaw = _prefs.getStringList(_keyExpenses) ?? [];
    final List<String> updated = [];
    for (var eStr in expensesRaw) {
      final e = Expense.fromJson(json.decode(eStr));
      if (e.id != id) {
        updated.add(eStr);
      }
    }
    await _prefs.setStringList(_keyExpenses, updated);
  }

  // --- Budgets ---

  @override
  Future<Budget?> getBudget({required int month, required int year}) async {
    final family = await getCurrentFamily();
    if (family == null) return null;

    final budgetsRaw = _prefs.getStringList(_keyBudgets) ?? [];
    for (var bStr in budgetsRaw) {
      final b = Budget.fromJson(json.decode(bStr));
      if (b.familyId == family.id && b.month == month && b.year == year) {
        return b;
      }
    }
    return null;
  }

  @override
  Future<Budget> setBudget({required double amount, required int month, required int year}) async {
    final family = await getCurrentFamily();
    if (family == null) {
      throw Exception('Must be in a family to set budget.');
    }

    final budgetsRaw = _prefs.getStringList(_keyBudgets) ?? [];
    Budget? existing;
    final List<String> updated = [];

    for (var bStr in budgetsRaw) {
      final b = Budget.fromJson(json.decode(bStr));
      if (b.familyId == family.id && b.month == month && b.year == year) {
        existing = b.copyWith(monthlyBudget: amount);
      } else {
        updated.add(bStr);
      }
    }

    if (existing == null) {
      final id = 'budget_${Random().nextInt(900000) + 100000}';
      existing = Budget(
        id: id,
        familyId: family.id,
        monthlyBudget: amount,
        month: month,
        year: year,
      );
    }

    updated.add(json.encode(existing.toJson()));
    await _prefs.setStringList(_keyBudgets, updated);
    return existing;
  }
}
