import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';

abstract class DbService {
  // Authentication
  Future<String?> signUp({required String email, required String password, required String displayName});
  Future<String?> signIn({required String email, required String password});
  Future<void> signOut();
  String? getCurrentUserId();
  String? getCurrentUserEmail();
  Future<String?> getCurrentUserDisplayName();

  // Family Management
  Future<Family?> createFamily({required String name});
  Future<Family?> joinFamily({required String familyCode});
  Future<Family?> getCurrentFamily();
  Future<List<FamilyMember>> getFamilyMembers();
  Future<void> updateMemberDisplayName(String name);

  // Expenses
  Future<List<Expense>> getExpenses();
  Future<Expense> addExpense({
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  });
  Future<void> deleteExpense(String id);

  // Budget
  Future<Budget?> getBudget({required int month, required int year});
  Future<Budget> setBudget({required double amount, required int month, required int year});
}
