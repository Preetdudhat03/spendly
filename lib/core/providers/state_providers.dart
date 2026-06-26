import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/providers/auth_providers.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';

// ==========================================
// 1. Authentication State & Provider
// ==========================================

class AuthState {
  final bool isLoading;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? error;
  
  // Migration support fields
  final bool isMigrationPending;
  final String? legacyUserId;
  final String? pendingPassword;

  AuthState({
    required this.isLoading,
    this.userId,
    this.email,
    this.displayName,
    this.error,
    this.isMigrationPending = false,
    this.legacyUserId,
    this.pendingPassword,
  });

  factory AuthState.initial() => AuthState(isLoading: false);

  AuthState copyWith({
    bool? isLoading,
    String? userId,
    String? email,
    String? displayName,
    String? error,
    bool? isMigrationPending,
    String? legacyUserId,
    String? pendingPassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      error: error,
      isMigrationPending: isMigrationPending ?? this.isMigrationPending,
      legacyUserId: legacyUserId ?? this.legacyUserId,
      pendingPassword: pendingPassword ?? this.pendingPassword,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DbService _dbService;
  final Ref _ref;

  AuthNotifier(this._dbService, this._ref) : super(AuthState.initial()) {
    // Listen to native Supabase Auth user changes
    _ref.listen(currentUserProvider, (previous, nextUser) {
      _updateStateFromProviders();
    });

    // Listen to native Profile changes
    _ref.listen(profileProvider, (previous, nextProfile) {
      _updateStateFromProviders();
    });

    // Run initial checks
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    state = state.copyWith(isLoading: true);
    
    // Check native user first
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      _updateStateFromProviders();
      _ref.read(familyProvider.notifier).loadFamily();
      return;
    }

    // Check legacy user in SharedPreferences
    final legacyId = _dbService.getCurrentUserId();
    if (legacyId != null) {
      final email = _dbService.getCurrentUserEmail();
      final displayName = await _dbService.getCurrentUserDisplayName();
      state = AuthState(
        isLoading: false,
        userId: legacyId,
        email: email,
        displayName: displayName,
      );
      _ref.read(familyProvider.notifier).loadFamily();
    } else {
      state = AuthState.initial();
    }
  }

  void _updateStateFromProviders() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      // If legacy session still exists in SharedPreferences, keep it active
      final legacyId = _dbService.getCurrentUserId();
      if (legacyId != null && !state.isMigrationPending) {
        return; // Don't wipe legacy session if active
      }
      if (!state.isMigrationPending) {
        state = AuthState.initial();
      }
      return;
    }

    // Native user is logged in
    final profileAsync = _ref.read(profileProvider);
    profileAsync.when(
      data: (profile) {
        if (profile != null) {
          // If the profile exists but migration is not completed, auto-trigger the transactional migration
          final legacyId = profile.legacyUserId ?? state.legacyUserId;
          if (!profile.migrationCompleted && legacyId != null) {
            _autoCompleteMigration(legacyId, profile.id);
            return;
          }

          state = AuthState(
            isLoading: false,
            userId: profile.id,
            email: profile.email,
            displayName: profile.displayName.isNotEmpty ? profile.displayName : (user.userMetadata?['display_name'] as String? ?? 'User'),
            isMigrationPending: false,
          );
          _ref.read(familyProvider.notifier).loadFamily();
        } else {
          // Profile doesn't exist yet (e.g. email is not confirmed)
          // Keep the migration pending view active during signup/migration check
          if (state.isMigrationPending) {
            return;
          }
          
          state = AuthState(
            isLoading: false,
            userId: user.id,
            email: user.email,
            displayName: user.userMetadata?['display_name'] as String? ?? 'User',
          );
        }
      },
      loading: () {
        if (!state.isLoading) {
          state = state.copyWith(isLoading: true);
        }
      },
      error: (e, s) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  Future<void> _autoCompleteMigration(String legacyUserId, String newUserId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('Supabase Auth: auto-completing migration for legacy user $legacyUserId to new native user $newUserId');
      await _dbService.completeUserMigration(legacyUserId, newUserId);
      
      // Refresh profile to trigger state reload with completed = true
      await _ref.read(profileNotifierProvider(newUserId).notifier).refresh();
      
      state = AuthState(
        isLoading: false,
        userId: newUserId,
        email: _ref.read(currentUserProvider)?.email,
        displayName: state.displayName,
        isMigrationPending: false,
      );
      
      _ref.read(familyProvider.notifier).loadFamily();
    } catch (e) {
      debugPrint('Supabase Auth: auto-complete migration failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Try native Supabase Auth sign-in
      try {
        final client = Supabase.instance.client;
        final response = await client.auth.signInWithPassword(
          email: email.toLowerCase().trim(),
          password: password,
        );
        if (response.user != null) {
          _updateStateFromProviders();
          return true;
        }
      } on AuthException catch (supabaseError) {
        final msg = supabaseError.message.toLowerCase();
        // If it's invalid credentials, check legacy database
        if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
          final client = Supabase.instance.client;
          final legacyUser = await client.from('users').select().eq('email', email.toLowerCase().trim()).maybeSingle();
          if (legacyUser == null) {
            state = state.copyWith(isLoading: false, error: 'Invalid email or password.');
            return false;
          }

          // Check legacy password
          final hashedInput = CryptoUtils.hashPassword(password);
          if (legacyUser['password'] != hashedInput) {
            state = state.copyWith(isLoading: false, error: 'Invalid email or password.');
            return false;
          }

          // Credentials match legacy database! Migration required.
          final legacyUserId = legacyUser['id'] as String;
          
          // Check if already completed migration
          final existingProfile = await client.from('profiles').select().eq('legacy_user_id', legacyUserId).maybeSingle();
          if (existingProfile != null && existingProfile['migration_completed'] == true) {
            state = state.copyWith(
              isLoading: false,
              error: 'Your account was already migrated. Please use your updated Supabase Auth password.',
            );
            return false;
          }

          // Trigger migration flow
          state = AuthState(
            isLoading: false,
            userId: legacyUserId,
            email: legacyUser['email'] as String,
            displayName: legacyUser['display_name'] as String,
            isMigrationPending: true,
            legacyUserId: legacyUserId,
            pendingPassword: password,
          );
          return true;
        } else if (msg.contains('email not confirmed')) {
          state = AuthState(
            isLoading: false,
            email: email.toLowerCase().trim(),
            isMigrationPending: false,
            error: 'Please verify your email address before logging in.',
          );
          return false;
        } else {
          state = state.copyWith(isLoading: false, error: supabaseError.message);
          return false;
        }
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: email.toLowerCase().trim(),
        password: password,
        data: {'display_name': displayName},
      );
      if (response.user != null) {
        state = AuthState(
          isLoading: false,
          email: email.toLowerCase().trim(),
          displayName: displayName,
          error: 'Registration successful! A verification email has been sent. Please confirm your email.',
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Sign up failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _dbService.signOut();
    state = AuthState.initial();
    _ref.read(familyProvider.notifier).reset();
    _ref.read(expenseProvider.notifier).reset();
    _ref.read(budgetProvider.notifier).reset();
  }

  Future<void> updateProfileName(String newName) async {
    try {
      await _dbService.updateMemberDisplayName(newName);
      state = state.copyWith(displayName: newName);
      
      // Refresh native profile notifier
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(profileNotifierProvider(user.id).notifier).refresh();
      }

      // Reload family members to update list UI
      _ref.read(familyProvider.notifier).loadMembers();
      // Reload expenses to update createdByName cache
      _ref.read(expenseProvider.notifier).loadExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      await client.auth.resetPasswordForEmail(
        email.toLowerCase().trim(),
        redirectTo: kIsWeb ? null : 'spendly://reset-password',
      );
      state = state.copyWith(isLoading: false);
      return 'SUCCESS';
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> startMigrationSignUp() async {
    if (!state.isMigrationPending || state.email == null || state.pendingPassword == null) {
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      await client.auth.signUp(
        email: state.email!,
        password: state.pendingPassword!,
        data: {
          'display_name': state.displayName ?? 'User',
          'legacy_user_id': state.legacyUserId,
        },
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already exists') || msg.contains('already registered')) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyAndCompleteMigration() async {
    if (!state.isMigrationPending || state.email == null || state.pendingPassword == null || state.legacyUserId == null) {
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      
      // 1. Confirm email is verified by attempting native sign-in
      final response = await client.auth.signInWithPassword(
        email: state.email!,
        password: state.pendingPassword!,
      );
      
      final newUser = response.user;
      if (newUser == null) {
        throw Exception('Failed to sign in. Please verify your email first.');
      }
      
      // 2. Perform atomic database migration via RPC
      await _dbService.completeUserMigration(state.legacyUserId!, newUser.id);
      
      // 3. Clear migration pending flag and complete login
      state = AuthState(
        isLoading: false,
        userId: newUser.id,
        email: newUser.email,
        displayName: state.displayName,
      );
      
      // Refresh profile and family
      await _ref.read(profileNotifierProvider(newUser.id).notifier).refresh();
      _ref.read(familyProvider.notifier).loadFamily();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void cancelMigration() {
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(dbServiceProvider);
  return AuthNotifier(db, ref);
});

// ==========================================
// 2. Family State & Provider
// ==========================================

class FamilyState {
  final bool isLoading;
  final Family? family;
  final List<FamilyMember> members;
  final String? error;

  FamilyState({
    required this.isLoading,
    this.family,
    required this.members,
    this.error,
  });

  factory FamilyState.initial() => FamilyState(isLoading: false, members: []);

  FamilyState copyWith({
    bool? isLoading,
    Family? family,
    List<FamilyMember>? members,
    String? error,
  }) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      family: family ?? this.family,
      members: members ?? this.members,
      error: error,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final DbService _dbService;
  final Ref _ref;

  FamilyNotifier(this._dbService, this._ref) : super(FamilyState.initial());

  void reset() {
    state = FamilyState.initial();
  }

  Future<void> loadFamily() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _dbService.getCurrentFamily();
      if (family != null) {
        final members = await _dbService.getFamilyMembers();
        state = FamilyState(isLoading: false, family: family, members: members);
        // Automatically load expenses and budgets
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
      } else {
        state = FamilyState.initial();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMembers() async {
    if (state.family == null) return;
    try {
      final members = await _dbService.getFamilyMembers();
      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> createFamily(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _dbService.createFamily(name: name);
      if (family != null) {
        final members = await _dbService.getFamilyMembers();
        state = FamilyState(isLoading: false, family: family, members: members);
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Could not create family');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> joinFamily(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _dbService.joinFamily(familyCode: code);
      if (family != null) {
        final members = await _dbService.getFamilyMembers();
        state = FamilyState(isLoading: false, family: family, members: members);
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Could not join family');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final db = ref.watch(dbServiceProvider);
  return FamilyNotifier(db, ref);
});

// ==========================================
// 3. Expenses State & Provider
// ==========================================

class ExpenseState {
  final bool isLoading;
  final List<Expense> expenses;
  final String? error;

  ExpenseState({
    required this.isLoading,
    required this.expenses,
    this.error,
  });

  factory ExpenseState.initial() => ExpenseState(isLoading: false, expenses: []);

  ExpenseState copyWith({
    bool? isLoading,
    List<Expense>? expenses,
    String? error,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      error: error,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DbService _dbService;

  ExpenseNotifier(this._dbService) : super(ExpenseState.initial());

  void reset() {
    state = ExpenseState.initial();
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _dbService.getExpenses();
      state = ExpenseState(isLoading: false, expenses: expenses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.addExpense(
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );
      // Reload expenses list
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.deleteExpense(id);
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.updateExpense(
        id: id,
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final db = ref.watch(dbServiceProvider);
  return ExpenseNotifier(db);
});

// ==========================================
// 4. Budget State & Provider
// ==========================================

class BudgetState {
  final bool isLoading;
  final Budget? currentBudget;
  final String? error;

  BudgetState({
    required this.isLoading,
    this.currentBudget,
    this.error,
  });

  factory BudgetState.initial() => BudgetState(isLoading: false);

  BudgetState copyWith({
    bool? isLoading,
    Budget? currentBudget,
    String? error,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      currentBudget: currentBudget ?? this.currentBudget,
      error: error,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final DbService _dbService;

  BudgetNotifier(this._dbService) : super(BudgetState.initial());

  void reset() {
    state = BudgetState.initial();
  }

  Future<void> loadBudget() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final budget = await _dbService.getBudget(month: now.month, year: now.year);
      state = BudgetState(isLoading: false, currentBudget: budget);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setBudget(double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final budget = await _dbService.setBudget(amount: amount, month: now.month, year: now.year);
      state = BudgetState(isLoading: false, currentBudget: budget);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final db = ref.watch(dbServiceProvider);
  return BudgetNotifier(db);
});

// ==========================================
// 5. Connection Status & Provider
// ==========================================

enum ConnectionStatus { checking, online, offline, sandbox }

class ConnectionNotifier extends StateNotifier<ConnectionStatus> {
  final DbService _dbService;
  Timer? _timer;

  ConnectionNotifier(this._dbService) : super(ConnectionStatus.checking) {
    checkConnection();
    // Run connection checks every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => checkConnection());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      state = ConnectionStatus.sandbox;
      return;
    }
    
    try {
      // Try to query users table
      await Supabase.instance.client.from('users').select('id').limit(1);
      state = ConnectionStatus.online;
    } on PostgrestException catch (e) {
      // If table doesn't exist but we get database response, we are online!
      debugPrint('Connection check: PostgrestException (Supabase is reachable): $e');
      state = ConnectionStatus.online;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      state = ConnectionStatus.offline;
    }
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionStatus>((ref) {
  final db = ref.watch(dbServiceProvider);
  return ConnectionNotifier(db);
});

// ==========================================
// 6. Blacklisted Suggestions Provider
// ==========================================

class BlacklistSuggestionsNotifier extends StateNotifier<Set<String>> {
  BlacklistSuggestionsNotifier() : super({}) {
    _loadBlacklist();
  }

  static const _prefKey = 'blacklisted_suggestions';

  Future<void> _loadBlacklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey);
      if (list != null) {
        state = list.toSet();
      }
    } catch (e) {
      debugPrint('Error loading blacklisted suggestions: $e');
    }
  }

  Future<void> blacklist(String key) async {
    state = {...state, key};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, state.toList());
    } catch (e) {
      debugPrint('Error saving blacklisted suggestions: $e');
    }
  }

  Future<void> clearBlacklist() async {
    state = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (e) {
      debugPrint('Error clearing blacklisted suggestions: $e');
    }
  }
}

final blacklistSuggestionsProvider = StateNotifierProvider<BlacklistSuggestionsNotifier, Set<String>>((ref) {
  return BlacklistSuggestionsNotifier();
});

// ==========================================
// 7. Package Info Provider
// ==========================================

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});
