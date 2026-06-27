import 'package:hive/hive.dart';
import 'package:spendly/models/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String familyId;

  @HiveField(2)
  final String createdBy;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final String paymentMethod;

  @HiveField(7)
  final DateTime expenseDate;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final String createdByName;

  ExpenseModel({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.amount,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdAt,
    required this.createdByName,
  });

  factory ExpenseModel.fromDomain(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      familyId: expense.familyId,
      createdBy: expense.createdBy,
      amount: expense.amount,
      category: expense.category,
      description: expense.description,
      paymentMethod: expense.paymentMethod,
      expenseDate: expense.expenseDate,
      createdAt: expense.createdAt,
      createdByName: expense.createdByName,
    );
  }

  Expense toDomain() {
    return Expense(
      id: id,
      familyId: familyId,
      createdBy: createdBy,
      amount: amount,
      category: category,
      description: description,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      createdAt: createdAt,
      createdByName: createdByName,
    );
  }
}
