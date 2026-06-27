import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseRepository {
  final _uuid = const Uuid();

  // Watch expenses for a family, returns a Stream or we can just provide data
  // Since Hive has watch(), we can use it to rebuild UI immediately.
  List<Expense> getExpenses(String familyId) {
    return HiveService.expenses.values
        .where((e) => e.familyId == familyId)
        .map((e) => e.toDomain())
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  Future<Expense> addExpense({
    required String familyId,
    required String createdBy,
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
    required String createdByName,
  }) async {
    // 1. Create with a temporary local ID
    final tempId = 'local_${_uuid.v4()}';
    final now = DateTime.now();

    final expense = Expense(
      id: tempId,
      familyId: familyId,
      createdBy: createdBy,
      amount: amount,
      category: category,
      description: description,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      createdAt: now,
      createdByName: createdByName,
    );

    // 2. Save immediately to Hive
    final hiveModel = ExpenseModel.fromDomain(expense);
    await HiveService.expenses.put(tempId, hiveModel);

    // 3. Queue Pending Operation
    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'ADD_EXPENSE',
      payload: expense.toJson(),
      userId: createdBy,
      familyId: familyId,
      timestamp: now,
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);

    return expense;
  }

  Future<Expense> updateExpense(Expense updatedExpense) async {
    // 1. Update in Hive
    final hiveModel = ExpenseModel.fromDomain(updatedExpense);
    await HiveService.expenses.put(updatedExpense.id, hiveModel);

    // 2. Queue Pending Operation
    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'UPDATE_EXPENSE',
      payload: updatedExpense.toJson(),
      userId: updatedExpense.createdBy,
      familyId: updatedExpense.familyId,
      timestamp: DateTime.now(),
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);

    return updatedExpense;
  }

  Future<void> deleteExpense(String expenseId, String familyId, String userId) async {
    // 1. Delete from Hive
    await HiveService.expenses.delete(expenseId);

    // 2. Queue Pending Operation
    final pendingOp = PendingOperationModel(
      id: _uuid.v4(),
      type: 'DELETE_EXPENSE',
      payload: {'id': expenseId},
      userId: userId,
      familyId: familyId,
      timestamp: DateTime.now(),
    );
    await HiveService.pendingOperations.put(pendingOp.id, pendingOp);
  }
}
