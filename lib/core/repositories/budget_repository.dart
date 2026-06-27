import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/budget.dart';
import 'package:spendly/models/hive/budget_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

class BudgetRepository {
  final _uuid = const Uuid();

  Budget? getBudget(String familyId, int month, int year) {
    try {
      final budgetModel = HiveService.budgets.values.firstWhere(
        (b) => b.familyId == familyId && b.month == month && b.year == year,
      );
      return budgetModel.toDomain();
    } catch (_) {
      return null;
    }
  }

  Future<Budget> setBudget({
    required String familyId,
    required double monthlyBudget,
    required int month,
    required int year,
    required String userId,
  }) async {
    // Find existing or create new
    String id;
    try {
      final existing = HiveService.budgets.values.firstWhere(
        (b) => b.familyId == familyId && b.month == month && b.year == year,
      );
      id = existing.id;
    } catch (_) {
      id = 'local_${_uuid.v4()}';
    }

    final budget = Budget(
      id: id,
      familyId: familyId,
      monthlyBudget: monthlyBudget,
      month: month,
      year: year,
    );

    // Save to Hive
    final hiveModel = BudgetModel.fromDomain(budget);
    await HiveService.budgets.put(id, hiveModel);

    // Queue operation
    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'SET_BUDGET',
      payload: budget.toJson(),
      userId: userId,
      familyId: familyId,
      timestamp: DateTime.now(),
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);

    return budget;
  }
}
