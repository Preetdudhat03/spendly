import re

def main():
    file_path = 'p:/pro/spendly/lib/core/providers/state_providers.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Replace DbService import
    content = content.replace("import 'package:spendly/core/services/db_provider.dart';", 
"""import 'package:spendly/core/repositories/expense_repository.dart';
import 'package:spendly/core/repositories/budget_repository.dart';
import 'package:spendly/core/repositories/family_repository.dart';
import 'package:spendly/core/repositories/profile_repository.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/db_provider.dart';""")

    # We need to change FamilyNotifier
    content = content.replace(
        "class FamilyNotifier extends StateNotifier<FamilyState> {\n  final DbService _dbService;\n  final Ref _ref;\n\n  FamilyNotifier(this._dbService, this._ref) : super(FamilyState.initial());",
        "class FamilyNotifier extends StateNotifier<FamilyState> {\n  final FamilyRepository _familyRepo;\n  final Ref _ref;\n\n  FamilyNotifier(this._familyRepo, this._ref) : super(FamilyState.initial()) {\n    HiveService.families.watch().listen((_) => loadFamily());\n    HiveService.familyMembers.watch().listen((_) => loadFamily());\n  }"
    )
    content = content.replace(
        "final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {\n  final db = ref.watch(dbServiceProvider);\n  return FamilyNotifier(db, ref);\n});",
        "final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {\n  final repo = ref.watch(familyRepositoryProvider);\n  return FamilyNotifier(repo, ref);\n});"
    )
    content = content.replace("await _dbService.getCurrentFamily()", "await Future.value(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? ''))")
    content = content.replace("await _dbService.getFamilyMembers()", "await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''))")
    content = content.replace("await _dbService.createFamily(name)", "await _familyRepo.createFamily(name, HiveService.settings.get('active_user_id') ?? '', 'Admin')")
    content = content.replace("await _dbService.joinFamily(familyCode)", "await _familyRepo.joinFamily(familyCode, HiveService.settings.get('active_user_id') ?? '', 'Member')")

    # Change ExpenseNotifier
    content = content.replace(
        "class ExpenseNotifier extends StateNotifier<ExpenseState> {\n  final DbService _dbService;\n\n  ExpenseNotifier(this._dbService) : super(ExpenseState.initial());",
        "class ExpenseNotifier extends StateNotifier<ExpenseState> {\n  final ExpenseRepository _expenseRepo;\n  final FamilyRepository _familyRepo;\n\n  ExpenseNotifier(this._expenseRepo, this._familyRepo) : super(ExpenseState.initial()) {\n    HiveService.expenses.watch().listen((_) => loadExpenses());\n  }"
    )
    content = content.replace(
        "final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {\n  final db = ref.watch(dbServiceProvider);\n  return ExpenseNotifier(db);\n});",
        "final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {\n  final expenseRepo = ref.watch(expenseRepositoryProvider);\n  final familyRepo = ref.watch(familyRepositoryProvider);\n  return ExpenseNotifier(expenseRepo, familyRepo);\n});"
    )
    content = content.replace("await _dbService.getExpenses()", "await Future.value(_expenseRepo.getExpenses(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''))")
    
    # AddExpense inside ExpenseNotifier
    content = content.replace(
        """await _dbService.addExpense(
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );""",
        """await _expenseRepo.addExpense(
        familyId: _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '',
        createdBy: HiveService.settings.get('active_user_id') ?? '',
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        createdByName: HiveService.profiles.get(HiveService.settings.get('active_user_id'))?.displayName ?? 'User',
      );"""
    )

    # DeleteExpense inside ExpenseNotifier
    content = content.replace(
        "await _dbService.deleteExpense(id);",
        "await _expenseRepo.deleteExpense(id, _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '', HiveService.settings.get('active_user_id') ?? '');"
    )
    
    # UpdateExpense
    content = content.replace(
        """await _dbService.updateExpense(
        id: id,
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );""",
      """
      final currentExpense = _expenseRepo.getExpenses(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '').firstWhere((e) => e.id == id);
      await _expenseRepo.updateExpense(
        currentExpense.copyWith(
          amount: amount,
          category: category,
          description: description,
          paymentMethod: paymentMethod,
          expenseDate: expenseDate,
        )
      );"""
    )
    
    # Change BudgetNotifier
    content = content.replace(
        "class BudgetNotifier extends StateNotifier<BudgetState> {\n  final DbService _dbService;\n\n  BudgetNotifier(this._dbService) : super(BudgetState.initial());",
        "class BudgetNotifier extends StateNotifier<BudgetState> {\n  final BudgetRepository _budgetRepo;\n  final FamilyRepository _familyRepo;\n\n  BudgetNotifier(this._budgetRepo, this._familyRepo) : super(BudgetState.initial()) {\n    HiveService.budgets.watch().listen((_) => loadBudget());\n  }"
    )
    content = content.replace(
        "final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {\n  final db = ref.watch(dbServiceProvider);\n  return BudgetNotifier(db);\n});",
        "final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {\n  final budgetRepo = ref.watch(budgetRepositoryProvider);\n  final familyRepo = ref.watch(familyRepositoryProvider);\n  return BudgetNotifier(budgetRepo, familyRepo);\n});"
    )
    content = content.replace("await _dbService.getBudget(month: month, year: year)", "await Future.value(_budgetRepo.getBudget(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '', month, year))")
    content = content.replace(
        """await _dbService.setBudget(
        monthlyBudget: amount,
        month: month,
        year: year,
      );""",
      """await _budgetRepo.setBudget(
        familyId: _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '',
        userId: HiveService.settings.get('active_user_id') ?? '',
        monthlyBudget: amount,
        month: month,
        year: year,
      );"""
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == "__main__":
    main()
