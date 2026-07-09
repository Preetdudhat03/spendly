import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/utils/error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/providers/auth_providers.dart';
import 'package:spendly/core/repositories/expense_repository.dart';
import 'package:spendly/core/repositories/budget_repository.dart';
import 'package:spendly/core/repositories/family_repository.dart';
import 'package:spendly/core/repositories/profile_repository.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/repositories/expense_repository.dart';
import 'package:spendly/core/repositories/budget_repository.dart';
import 'package:spendly/core/repositories/family_repository.dart';
import 'package:spendly/core/repositories/profile_repository.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/main.dart';
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
    // Postpone to next microtask to avoid Riverpod modify-while-building errors
    await Future.microtask(() {});
    
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
      HiveService.settings.put('active_user_id', legacyId);
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
          HiveService.settings.put('active_user_id', profile.id);
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
          HiveService.settings.put('active_user_id', user.id);
          _ref.read(familyProvider.notifier).loadFamily();
        }
      },
      loading: () {
        if (!state.isLoading) {
          state = state.copyWith(isLoading: true);
        }
      },
      error: (e, s) {
        state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
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
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Fallback to local DB Service if Supabase is not configured or initialized
      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        try {
          final userId = await _dbService.signIn(email: cleanEmail, password: password);
          if (userId != null) {
            final displayName = await _dbService.getCurrentUserDisplayName();
            state = AuthState(
              isLoading: false,
              userId: userId,
              email: cleanEmail,
              displayName: displayName,
            );
            HiveService.settings.put('active_user_id', userId);
            _ref.read(familyProvider.notifier).loadFamily();
            return true;
          }
        } catch (e) {
          final errorMsg = ErrorHelper.getReadableErrorMessage(e);
          if (errorMsg.contains('USER_NOT_FOUND')) {
            state = state.copyWith(isLoading: false, error: 'USER_NOT_FOUND');
          } else {
            state = state.copyWith(isLoading: false, error: errorMsg.replaceAll('Exception: ', ''));
          }
          return false;
        }
        state = state.copyWith(isLoading: false, error: 'Authentication failed');
        return false;
      }

      // 1. Try native Supabase Auth sign-in
      try {
        final client = Supabase.instance.client;
        final response = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (response.user != null) {
          await _ref.read(syncServiceProvider).mergeLocalDataToCloud(response.user!.id);
          _updateStateFromProviders();
          return true;
        }
      } on AuthException catch (supabaseError) {
        final msg = supabaseError.message.toLowerCase();
        // If it's invalid credentials, check legacy database
        if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
          final client = Supabase.instance.client;
          
          final legacyUser = await client.from('users').select().eq('email', cleanEmail).maybeSingle();
          final nativeProfile = await client.from('profiles').select().eq('email', cleanEmail).maybeSingle();
          
          if (legacyUser == null && nativeProfile == null) {
            state = state.copyWith(isLoading: false, error: 'USER_NOT_FOUND');
            return false;
          }

          if (legacyUser != null) {
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
          } else {
            // Native profile exists, but password was wrong
            state = state.copyWith(isLoading: false, error: 'Invalid email or password.');
            return false;
          }
        } else if (msg.contains('email not confirmed')) {
          state = AuthState(
            isLoading: false,
            email: cleanEmail,
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
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Fallback to local DB Service if Supabase is not configured or initialized
      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        final userId = await _dbService.signUp(
          email: cleanEmail,
          password: password,
          displayName: displayName,
        );
        if (userId != null) {
          state = AuthState(
            isLoading: false,
            email: cleanEmail,
            displayName: displayName,
            error: 'Registration successful! You can now log in.',
          );
          return true;
        }
        state = state.copyWith(isLoading: false, error: 'Registration failed');
        return false;
      }

      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'display_name': displayName},
      );
      if (response.user != null) {
        if (response.session != null) {
           await _ref.read(syncServiceProvider).mergeLocalDataToCloud(response.user!.id);
        }
        state = AuthState(
          isLoading: false,
          email: cleanEmail,
          displayName: displayName,
          error: 'Registration successful! A verification email has been sent. Please confirm your email.',
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Sign up failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await HiveService.settings.delete('active_user_id');
    await _dbService.signOut();
    state = AuthState.initial();
    _ref.read(familyProvider.notifier).reset();
    _ref.read(expenseProvider.notifier).reset();
    _ref.read(budgetProvider.notifier).reset();
  }

  Future<void> deleteAccount() async {
    final currentId = state.userId;
    if (currentId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.deleteUserAccount(currentId);
      await signOut();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      rethrow;
    }
  }

  Future<void> updateProfileName(String newName) async {
    try {
      final currentId = state.userId;
      if (currentId != null) {
        await _dbService.updateMemberDisplayName(newName);
        await _ref.read(profileRepositoryProvider).updateDisplayName(currentId, newName);
      }
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
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<void> updateAvatarColor(String colorHex) async {
    try {
      await _dbService.updateMemberAvatarColor(colorHex);
      
      // Refresh native profile notifier
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(profileNotifierProvider(user.id).notifier).refresh();
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await _dbService.updateEmail(newEmail);
      state = state.copyWith(email: newEmail.toLowerCase().trim());
      
      // Refresh native profile notifier
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(profileNotifierProvider(user.id).notifier).refresh();
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
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
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return null;
    }
  }

  Future<bool> startMigrationSignUp() async {
    debugPrint('Supabase Auth: startMigrationSignUp called. isMigrationPending: ${state.isMigrationPending}, email: ${state.email}, pendingPassword length: ${state.pendingPassword?.length ?? 0}, legacyUserId: ${state.legacyUserId}');
    if (!state.isMigrationPending || state.email == null || state.pendingPassword == null) {
      debugPrint('Supabase Auth: startMigrationSignUp early exit. Conditions not met.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      debugPrint('Supabase Auth: calling signUp for ${state.email}');
      final response = await client.auth.signUp(
        email: state.email!,
        password: state.pendingPassword!,
        data: {
          'display_name': state.displayName ?? 'User',
          'legacy_user_id': state.legacyUserId,
        },
      );
      debugPrint('Supabase Auth: signUp success. User ID: ${response.user?.id}');
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      debugPrint('Supabase Auth: signUp AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('already exists') || 
          msg.contains('already registered') || 
          msg.contains('rate limit')) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      debugPrint('Supabase Auth: signUp generic error: $e');
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<bool> verifyAndCompleteMigration() async {
    debugPrint('Supabase Auth: verifyAndCompleteMigration called. isMigrationPending: ${state.isMigrationPending}, email: ${state.email}, legacyUserId: ${state.legacyUserId}');
    if (!state.isMigrationPending || state.email == null || state.pendingPassword == null || state.legacyUserId == null) {
      debugPrint('Supabase Auth: verifyAndCompleteMigration early exit. Conditions not met.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      debugPrint('Supabase Auth: attempting signInWithPassword for ${state.email}');
      
      // 1. Confirm email is verified by attempting native sign-in
      final response = await client.auth.signInWithPassword(
        email: state.email!,
        password: state.pendingPassword!,
      );
      
      final newUser = response.user;
      debugPrint('Supabase Auth: signInWithPassword success. User ID: ${newUser?.id}');
      if (newUser == null) {
        throw Exception('Failed to sign in. Please verify your email first.');
      }
      
      // 2. Perform atomic database migration via RPC
      debugPrint('Supabase Auth: calling completeUserMigration RPC for legacy user ${state.legacyUserId} to ${newUser.id}');
      await _dbService.completeUserMigration(state.legacyUserId!, newUser.id);
      debugPrint('Supabase Auth: completeUserMigration RPC success!');
      
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
      debugPrint('Supabase Auth: verifyAndCompleteMigration failed: $e');
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
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
  final bool hasLoaded;
  final Family? family;
  final List<FamilyMember> members;
  final String? error;

  FamilyState({
    required this.isLoading,
    this.hasLoaded = false,
    this.family,
    required this.members,
    this.error,
  });

  factory FamilyState.initial() => FamilyState(
        isLoading: false,
        hasLoaded: false,
        members: [],
      );

  FamilyState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    Family? family,
    List<FamilyMember>? members,
    String? error,
  }) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      family: family ?? this.family,
      members: members ?? this.members,
      error: error,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final FamilyRepository _familyRepo;
  final Ref _ref;

  FamilyNotifier(this._familyRepo, this._ref) : super(FamilyState.initial()) {
    HiveService.families.watch().listen((_) => loadFamily());
    HiveService.familyMembers.watch().listen((_) => loadFamily());
  }

  void reset() {
    state = FamilyState.initial();
  }

  Future<void> loadFamily() async {
    if (state.isLoading) return;

    // Background refresh if already loaded
    final isAlreadyLoaded = state.family != null;
    if (isAlreadyLoaded) {
      try {
        final family = await Future.value(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? ''));
        if (family != null) {
          final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
          state = FamilyState(
            isLoading: false,
            hasLoaded: true,
            family: family,
            members: members,
          );
          _ref.read(expenseProvider.notifier).loadExpenses();
          _ref.read(budgetProvider.notifier).loadBudget();
        } else {
          state = FamilyState.initial().copyWith(hasLoaded: true);
        }
      } catch (e) {
        state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await Future.value(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? ''));
      if (family != null) {
        final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
        state = FamilyState(
          isLoading: false,
          hasLoaded: true,
          family: family,
          members: members,
        );
        // Automatically load expenses and budgets
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
      } else {
        state = FamilyState.initial().copyWith(hasLoaded: true);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
    }
  }

  Future<void> loadMembers() async {
    if (state.family == null) return;
    try {
      final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<bool> createFamily(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = _ref.read(authProvider);
      final displayName = authState.displayName ?? 'User';
      final family = await _familyRepo.createFamily(name, HiveService.settings.get('active_user_id') ?? '', displayName);
      if (family != null) {
        final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
        state = FamilyState(
          isLoading: false,
          hasLoaded: true,
          family: family,
          members: members,
        );
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Could not create family',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> joinFamily(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = _ref.read(authProvider);
      final displayName = authState.displayName ?? 'User';
      final family = await _familyRepo.joinFamily(code, HiveService.settings.get('active_user_id') ?? '', displayName);
      if (family != null) {
        final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
        state = FamilyState(
          isLoading: false,
          hasLoaded: true,
          family: family,
          members: members,
        );
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Could not join family',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> deleteFamily() async {
    final familyId = state.family?.id;
    if (familyId == null) {
      state = state.copyWith(error: 'No active family found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // await _familyRepo.deleteFamily(familyId); // Implement if needed
      reset();
      _ref.read(expenseProvider.notifier).reset();
      _ref.read(budgetProvider.notifier).reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> removeMember(String targetUserId) async {
    try {
      await _familyRepo.removeMember(targetUserId);
      await loadMembers(); // Reload members after removing
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return FamilyNotifier(repo, ref);
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
  final ExpenseRepository _expenseRepo;
  final FamilyRepository _familyRepo;
  final Ref _ref;

  ExpenseNotifier(this._expenseRepo, this._familyRepo, this._ref) : super(ExpenseState.initial()) {
    HiveService.expenses.watch().listen((_) => loadExpenses());
  }

  void reset() {
    state = ExpenseState.initial();
  }

  Future<void> loadExpenses() async {
    if (state.isLoading) return;

    final isAlreadyLoaded = state.expenses.isNotEmpty;
    if (isAlreadyLoaded) {
      try {
        final expenses = await Future.value(_expenseRepo.getExpenses(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
        state = ExpenseState(isLoading: false, expenses: expenses);
      } catch (e) {
        state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await Future.value(_expenseRepo.getExpenses(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
      state = ExpenseState(isLoading: false, expenses: expenses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<bool> addExpense({
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _expenseRepo.addExpense(
        familyId: _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '',
        createdBy: HiveService.settings.get('active_user_id') ?? '',
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        createdByName: HiveService.profiles.get(HiveService.settings.get('active_user_id'))?.displayName ?? 'User',
      );
      state = state.copyWith(isLoading: false);
      // Reload expenses list
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _expenseRepo.deleteExpense(id, _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '', HiveService.settings.get('active_user_id') ?? '');
      state = state.copyWith(isLoading: false);
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
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
      
      final currentExpense = _expenseRepo.getExpenses(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '').firstWhere((e) => e.id == id);
      await _expenseRepo.updateExpense(
        currentExpense.copyWith(
          amount: amount,
          category: category,
          description: description,
          paymentMethod: paymentMethod,
          expenseDate: expenseDate,
        )
      );
      state = state.copyWith(isLoading: false);
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final familyRepo = ref.watch(familyRepositoryProvider);
  return ExpenseNotifier(expenseRepo, familyRepo, ref);
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
  final BudgetRepository _budgetRepo;
  final FamilyRepository _familyRepo;

  BudgetNotifier(this._budgetRepo, this._familyRepo) : super(BudgetState.initial()) {
    HiveService.budgets.watch().listen((_) => loadBudget());
  }

  void reset() {
    state = BudgetState.initial();
  }

  Future<void> loadBudget() async {
    if (state.isLoading) return;

    final isAlreadyLoaded = state.currentBudget != null;
    if (isAlreadyLoaded) {
      try {
        final now = DateTime.now();
        final budget = await Future.value(_budgetRepo.getBudget(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '', now.month, now.year));
        state = BudgetState(isLoading: false, currentBudget: budget);
      } catch (e) {
        state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final budget = await Future.value(_budgetRepo.getBudget(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '', now.month, now.year));
      state = BudgetState(isLoading: false, currentBudget: budget);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<void> setBudget(double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final budget = await _budgetRepo.setBudget(
        familyId: _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '',
        userId: HiveService.settings.get('active_user_id') ?? '',
        monthlyBudget: amount,
        month: now.month,
        year: now.year,
      );
      state = BudgetState(isLoading: false, currentBudget: budget);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final familyRepo = ref.watch(familyRepositoryProvider);
  return BudgetNotifier(budgetRepo, familyRepo);
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