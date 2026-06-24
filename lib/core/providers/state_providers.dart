import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/db_service.dart';
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

  AuthState({
    required this.isLoading,
    this.userId,
    this.email,
    this.displayName,
    this.error,
  });

  factory AuthState.initial() => AuthState(isLoading: false);

  AuthState copyWith({
    bool? isLoading,
    String? userId,
    String? email,
    String? displayName,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DbService _dbService;
  final Ref _ref;

  AuthNotifier(this._dbService, this._ref) : super(AuthState.initial()) {
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    state = state.copyWith(isLoading: true);
    final userId = _dbService.getCurrentUserId();
    if (userId != null) {
      final email = _dbService.getCurrentUserEmail();
      final displayName = await _dbService.getCurrentUserDisplayName();
      state = AuthState(
        isLoading: false,
        userId: userId,
        email: email,
        displayName: displayName,
      );
      // Automatically load family info
      _ref.read(familyProvider.notifier).loadFamily();
    } else {
      state = AuthState.initial();
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await _dbService.signIn(email: email, password: password);
      if (userId != null) {
        final userEmail = _dbService.getCurrentUserEmail();
        final displayName = await _dbService.getCurrentUserDisplayName();
        state = AuthState(
          isLoading: false,
          userId: userId,
          email: userEmail,
          displayName: displayName,
        );
        // Refresh family, expenses, budget
        _ref.read(familyProvider.notifier).loadFamily();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Sign in failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await _dbService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (userId != null) {
        state = AuthState(
          isLoading: false,
          userId: userId,
          email: email,
          displayName: displayName,
        );
        // Reset family to clear previous state
        _ref.read(familyProvider.notifier).reset();
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
      // Reload family members to update list UI
      _ref.read(familyProvider.notifier).loadMembers();
      // Reload expenses to update createdByName cache
      _ref.read(expenseProvider.notifier).loadExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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
