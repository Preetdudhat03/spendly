import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';

class SupabaseDbService implements DbService {
  final SupabaseClient _client = Supabase.instance.client;

  // Cache of user ID -> display name to quickly populate createdByName on expenses
  final Map<String, String> _memberNamesCache = {};

  // --- Authentication ---

  @override
  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return response.user?.id;
  }

  @override
  Future<String?> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user?.id;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _memberNamesCache.clear();
  }

  @override
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  @override
  String? getCurrentUserEmail() {
    return _client.auth.currentUser?.email;
  }

  @override
  Future<String?> getCurrentUserDisplayName() async {
    final metadata = _client.auth.currentUser?.userMetadata;
    return metadata?['display_name'] as String? ?? 'User';
  }

  // --- Family ---

  @override
  Future<Family?> createFamily({required String name}) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Must be logged in.');

    // Generate code: FAMILY-XXXX
    final int rand = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final code = 'FAMILY-$rand';

    // Insert family
    final familyData = await _client.from('families').insert({
      'name': name,
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

    // Get family members join
    final memberData = await _client
        .from('family_members')
        .select('family_id, families(*)')
        .eq('user_id', userId)
        .maybeSingle();

    if (memberData == null) return null;

    final familyRaw = memberData['families'];
    if (familyRaw == null) return null;

    return Family.fromJson(familyRaw as Map<String, dynamic>);
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers() async {
    final family = await getCurrentFamily();
    if (family == null) return [];

    final list = await _client.from('family_members').select().eq('family_id', family.id);
    final List<FamilyMember> members = [];

    for (var data in list) {
      // In a real database, we would query metadata or joins.
      // Here, we can query auth user details or fallback.
      final userId = data['user_id'] as String;
      
      // Let's resolve their display name if they are the current user
      String displayName = data['role'] == 'admin' ? 'Family Admin' : 'Family Member';
      if (userId == getCurrentUserId()) {
        displayName = await getCurrentUserDisplayName() ?? displayName;
      } else {
        // Fallback names for other users, or use cached names
        displayName = _memberNamesCache[userId] ?? displayName;
      }

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

    // Update user auth metadata
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': name}),
    );
    _memberNamesCache[userId] = name;
  }

  // --- Expenses ---

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

    final displayName = await getCurrentUserDisplayName() ?? 'Family Member';

    final data = await _client.from('expenses').insert({
      'family_id': family.id,
      'created_by': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'payment_method': paymentMethod,
      'expense_date': expenseDate.toIso8601String(),
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
}
