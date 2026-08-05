import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';

class SupabaseDbService implements DbService {
  final SupabaseClient _client = Supabase.instance.client;
  final SharedPreferences _prefs;

  SupabaseDbService(this._prefs);

  // Local storage session keys
  static const String _keySupaUserId = 'supabase_user_id';
  static const String _keySupaUserEmail = 'supabase_user_email';
  static const String _keySupaUserDisplayName = 'supabase_user_display_name';

  // Cache of user ID -> display name to quickly populate createdByName on expenses
  final Map<String, String> _memberNamesCache = {};

  // --- Authentication ---

  @override
  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    final cleanEmail = email.toLowerCase().trim();
    debugPrint('Supabase Auth: signUp requested for $cleanEmail');
    try {
      final hashedPassword = CryptoUtils.hashPassword(password);
      final response = await _client.from('users').insert({
        'email': cleanEmail,
        'password': hashedPassword,
        'display_name': displayName,
      }).select().single();

      debugPrint('Supabase Auth: signUp database insert succeeded: $response');
      final userId = response['id'] as String;

      await _prefs.setString(_keySupaUserId, userId);
      await _prefs.setString(_keySupaUserEmail, cleanEmail);
      await _prefs.setString(_keySupaUserDisplayName, displayName);

      return userId;
    } catch (e, stack) {
      debugPrint('Supabase Auth: signUp failed with exception: $e');
      debugPrint('Supabase Auth: signUp stacktrace: $stack');
      rethrow;
    }
  }

  @override
  Future<String?> signIn({required String email, required String password}) async {
    final normalizedEmail = email.toLowerCase().trim();
    debugPrint('Supabase Auth: signIn requested for $normalizedEmail');
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('email', normalizedEmail)
          .maybeSingle();

      debugPrint('Supabase Auth: signIn select result: $response');

      if (response == null) {
        debugPrint('Supabase Auth: signIn failed - email not found in database');
        throw Exception('Invalid email or password.');
      }

      final hashedPassword = CryptoUtils.hashPassword(password);
      if (response['password'] != hashedPassword) {
        debugPrint('Supabase Auth: signIn failed - password hash mismatch');
        throw Exception('Invalid email or password.');
      }

      final userId = response['id'] as String;
      final displayName = response['display_name'] as String;

      await _prefs.setString(_keySupaUserId, userId);
      await _prefs.setString(_keySupaUserEmail, normalizedEmail);
      await _prefs.setString(_keySupaUserDisplayName, displayName);

      debugPrint('Supabase Auth: signIn successful, session saved for user: $userId');
      return userId;
    } catch (e, stack) {
      debugPrint('Supabase Auth: signIn failed with exception: $e');
      debugPrint('Supabase Auth: signIn stacktrace: $stack');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.removeAllChannels();
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out from Supabase Auth: $e');
    }
    await _prefs.remove(_keySupaUserId);
    await _prefs.remove(_keySupaUserEmail);
    await _prefs.remove(_keySupaUserDisplayName);
    _memberNamesCache.clear();
  }

  @override
  String? getCurrentUserId() {
    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null) {
      return nativeUser.id;
    }
    return _prefs.getString(_keySupaUserId);
  }

  @override
  String? getCurrentUserEmail() {
    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null) {
      return nativeUser.email;
    }
    return _prefs.getString(_keySupaUserEmail);
  }

  @override
  Future<String?> getCurrentUserDisplayName() async {
    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null) {
      try {
        final profile = await _client.from('profiles').select('display_name').eq('id', nativeUser.id).maybeSingle();
        if (profile != null) {
          final name = profile['display_name'] as String?;
          if (name != null && name.isNotEmpty) return name;
        }
      } catch (e) {
        debugPrint('Error getting display name from profile: $e');
      }
      return nativeUser.userMetadata?['display_name'] as String? ?? 'User';
    }
    return _prefs.getString(_keySupaUserDisplayName) ?? 'User';
  }

  @override
  Future<String?> forgotPassword(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final response = await _client
        .from('users')
        .select()
        .eq('email', normalizedEmail)
        .maybeSingle();

    if (response == null) {
      throw Exception('Email not found.');
    }

    // Generate random 4-digit numeric temp password code
    final int rand = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final tempPassword = 'TEMP-$rand';

    // Update password in public.users table
    await _client
        .from('users')
        .update({'password': CryptoUtils.hashPassword(tempPassword)})
        .eq('email', normalizedEmail);

    return tempPassword;
  }

  @override
  Future<void> completeUserMigration(String oldUserId, String newUserId) async {
    debugPrint('Supabase Auth: completing user migration from $oldUserId to $newUserId');
    await _client.rpc('complete_user_migration', params: {
      'old_user_id': oldUserId,
      'new_user_id': newUserId,
    });
    
    // Clear legacy SharedPreferences session to complete cutover
    await _prefs.remove(_keySupaUserId);
    await _prefs.remove(_keySupaUserEmail);
    await _prefs.remove(_keySupaUserDisplayName);
  }

  // --- Family ---

  @override
  Future<Family?> createFamily({required String name}) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Must be logged in.');

    // Validate family name against strict schema
    final cleanName = SchemaValidator.validateDisplayName(name, fieldName: 'Family Name');

    // Generate code: FAMILY-XXXX
    final int rand = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final code = 'FAMILY-$rand';

    // Insert family
    final familyData = await _client.from('families').insert({
      'name': cleanName,
      'family_code': code,
      'created_by': userId,
    }).select().single();

    final family = Family.fromJson(familyData);

    // Insert creator as admin member
    final displayName = await getCurrentUserDisplayName() ?? 'Family Admin';
    await _client.from('family_members').insert({
      'family_id': family.id,
      'user_id': userId,
      'role': 'admin',
    });

    _memberNamesCache[userId] = displayName;
    return family;
  }

  @override
  Future<Family?> joinFamily({required String familyCode}) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Must be logged in.');

    // Find family
    final normalizedCode = familyCode.trim().toUpperCase();
    final familyList = await _client.from('families').select().eq('family_code', normalizedCode);

    if (familyList.isEmpty) {
      throw Exception('Family code not found.');
    }

    final family = Family.fromJson(familyList.first);

    // Check if already in family
    final memberList = await _client
        .from('family_members')
        .select()
        .eq('family_id', family.id)
        .eq('user_id', userId);

    if (memberList.isEmpty) {
      // Join family
      await _client.from('family_members').insert({
        'family_id': family.id,
        'user_id': userId,
        'role': 'member',
      });
    }

    return family;
  }

  @override
  Future<Family?> getCurrentFamily() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      // Get family ID for the user
      final memberData = await _client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberData == null) return null;

      final familyId = memberData['family_id'] as String?;
      if (familyId == null) return null;

      // Get family details using the family ID
      final familyData = await _client
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (familyData == null) return null;

      return Family.fromJson(familyData);
    } catch (e) {
      debugPrint('Supabase Auth: error fetching current family: $e');
      return null;
    }
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    final family = await getCurrentFamily();
    if (family == null) return [];

    final list = await _client
        .from('family_members')
        .select('*')
        .eq('family_id', family.id);
        
    if (list.isEmpty) return [];

    final List<String> userIds = list.map((data) => data['user_id'] as String).toList();

    // Query users (legacy) in bulk
    final Map<String, String> legacyNames = {};
    try {
      final legacyUsers = await _client
          .from('users')
          .select('id, display_name')
          .inFilter('id', userIds);
      for (var user in legacyUsers) {
        final id = user['id'] as String?;
        final name = user['display_name'] as String?;
        if (id != null && name != null) {
          legacyNames[id] = name;
        }
      }
    } catch (e) {
      debugPrint('Supabase Auth: error fetching legacy user names: $e');
    }

    // Query profiles (migrated) in bulk
    final Map<String, String> profileNames = {};
    try {
      final profiles = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', userIds);
      for (var profile in profiles) {
        final id = profile['id'] as String?;
        final name = profile['display_name'] as String?;
        if (id != null && name != null) {
          profileNames[id] = name;
        }
      }
    } catch (e) {
      debugPrint('Supabase Auth: error fetching profile names: $e');
    }

    final List<FamilyMember> members = [];

    for (var data in list) {
      final userId = data['user_id'] as String;
      final displayName = profileNames[userId] ?? 
          legacyNames[userId] ?? 
          (data['role'] == 'admin' ? 'Family Admin' : 'Family Member');

      final member = FamilyMember(
        id: data['id'] as String,
        familyId: data['family_id'] as String,
        userId: userId,
        role: data['role'] as String,
        joinedAt: DateTime.parse(data['joined_at'] as String),
        displayName: displayName,
      );

      _memberNamesCache[userId] = displayName;
      members.add(member);
    }

    return members;
  }

  @override
  Future<void> updateMemberDisplayName(String name) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null) {
      // Update display name in profiles table
      await _client
          .from('profiles')
          .update({'display_name': name})
          .eq('id', userId);
    } else {
      // Fallback for legacy user
      await _client
          .from('users')
          .update({'display_name': name})
          .eq('id', userId);
      await _prefs.setString(_keySupaUserDisplayName, name);
    }
    
    _memberNamesCache[userId] = name;
  }

  // --- Expenses ---

  @override
  Future<void> updateEmail(String newEmail) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    final cleanEmail = newEmail.toLowerCase().trim();

    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null) {
      // Update email in auth.users (which syncs to profiles via trigger)
      await _client.auth.updateUser(UserAttributes(email: cleanEmail));
    } else {
      // Fallback for legacy user
      await _client
          .from('users')
          .update({'email': cleanEmail})
          .eq('id', userId);
      await _prefs.setString(_keySupaUserEmail, cleanEmail);
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    final family = await getCurrentFamily();
    if (family == null) return [];

    // Pre-cache member names to map createdByName
    await getFamilyMembers();

    final list = await _client
        .from('expenses')
        .select()
        .eq('family_id', family.id)
        .order('expense_date', ascending: false);

    return list.map((data) {
      final createdBy = data['created_by'] as String;
      final name = _memberNamesCache[createdBy] ?? 'Family Member';
      
      return Expense(
        id: data['id'] as String,
        familyId: data['family_id'] as String,
        createdBy: createdBy,
        amount: (data['amount'] as num).toDouble(),
        category: data['category'] as String,
        description: data['description'] as String? ?? '',
        paymentMethod: data['payment_method'] as String? ?? 'UPI',
        expenseDate: DateTime.parse(data['expense_date'] as String),
        createdAt: DateTime.parse(data['created_at'] as String),
        createdByName: name,
      );
    }).toList();
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

    // Validate expense fields against strict schema
    final cleanAmount = SchemaValidator.validateExpenseAmount(amount);
    final cleanCategory = SchemaValidator.validateExpenseCategory(category);
    final cleanDescription = SchemaValidator.validateExpenseDescription(description);
    final cleanPaymentMethod = SchemaValidator.validatePaymentMethod(paymentMethod);
    final cleanDate = SchemaValidator.validateExpenseDate(expenseDate);

    final displayName = await getCurrentUserDisplayName() ?? 'Family Member';

    final data = await _client.from('expenses').insert({
      'family_id': family.id,
      'created_by': userId,
      'amount': cleanAmount,
      'category': cleanCategory,
      'description': cleanDescription,
      'payment_method': cleanPaymentMethod,
      'expense_date': cleanDate.toIso8601String(),
    }).select().single();

    return Expense(
      id: data['id'] as String,
      familyId: data['family_id'] as String,
      createdBy: data['created_by'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      description: data['description'] as String? ?? '',
      paymentMethod: data['payment_method'] as String? ?? 'UPI',
      expenseDate: DateTime.parse(data['expense_date'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      createdByName: displayName,
    );
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    // Validate expense fields against strict schema
    final cleanAmount = SchemaValidator.validateExpenseAmount(amount);
    final cleanCategory = SchemaValidator.validateExpenseCategory(category);
    final cleanDescription = SchemaValidator.validateExpenseDescription(description);
    final cleanPaymentMethod = SchemaValidator.validatePaymentMethod(paymentMethod);
    final cleanDate = SchemaValidator.validateExpenseDate(expenseDate);
    final displayName = await getCurrentUserDisplayName() ?? 'Family Member';
    final data = await _client.from('expenses').update({
      'amount': cleanAmount,
      'category': cleanCategory,
      'description': cleanDescription,
      'payment_method': cleanPaymentMethod,
      'expense_date': cleanDate.toIso8601String(),
    }).eq('id', id).select().single();

    return Expense(
      id: data['id'] as String,
      familyId: data['family_id'] as String,
      createdBy: data['created_by'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      description: data['description'] as String? ?? '',
      paymentMethod: data['payment_method'] as String? ?? 'UPI',
      expenseDate: DateTime.parse(data['expense_date'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      createdByName: displayName,
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // --- Budgets ---

  @override
  Future<Budget?> getBudget({required int month, required int year}) async {
    final family = await getCurrentFamily();
    if (family == null) return null;

    final data = await _client
        .from('budgets')
        .select()
        .eq('family_id', family.id)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (data == null) return null;
    return Budget.fromJson(data);
  }

  @override
  Future<Budget> setBudget({required double amount, required int month, required int year}) async {
    final family = await getCurrentFamily();
    if (family == null) throw Exception('Must be in a family.');

    final data = await _client.from('budgets').upsert({
      'family_id': family.id,
      'monthly_budget': amount,
      'month': month,
      'year': year,
    }, onConflict: 'family_id, month, year').select().single();

    return Budget.fromJson(data);
  }

  @override
  Future<void> deleteUserAccount(String userId) async {
    debugPrint('Supabase DB: deleteUserAccount requested for user $userId');
    final nativeUser = _client.auth.currentUser;
    if (nativeUser != null && nativeUser.id == userId) {
      debugPrint('Supabase DB: Native user deleting account via RPC');
      await _client.rpc('delete_user_account', params: {'target_user_id': userId});
      await signOut();
    } else {
      debugPrint('Supabase DB: Legacy user deleting account directly');
      // Delete from family members and users directly
      await _client.from('family_members').delete().eq('user_id', userId);
      await _client.from('users').delete().eq('id', userId);
      await signOut();
    }
  }

  @override
  Future<void> deleteFamily(String familyId) async {
    debugPrint('Supabase DB: deleteFamily requested for family $familyId');
    // Delete family record, database cascades will handle expenses, budgets, members
    await _client.from('families').delete().eq('id', familyId);
  }

  @override
  Future<void> removeFamilyMember(String userId) async {
    debugPrint('Supabase DB: removeFamilyMember requested for user $userId');
    // For standard members, removing them from the family_members table detaches them
    await _client.from('family_members').delete().eq('user_id', userId);
  }

  @override
  Future<void> updateMemberAvatarColor(String colorHex) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    debugPrint('Supabase DB: updateMemberAvatarColor requested for user $userId');
    await HiveService.settings.put('avatar_color', colorHex);
    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {'avatar_color': colorHex},
        ),
      );
    } catch (e) {
      debugPrint('Error updating user metadata in Supabase: $e');
    }
  }
}
