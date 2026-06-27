import 'package:hive/hive.dart';
import 'package:spendly/models/budget.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 3)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String familyId;

  @HiveField(2)
  final double monthlyBudget;

  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  BudgetModel({
    required this.id,
    required this.familyId,
    required this.monthlyBudget,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromDomain(Budget budget) {
    return BudgetModel(
      id: budget.id,
      familyId: budget.familyId,
      monthlyBudget: budget.monthlyBudget,
      month: budget.month,
      year: budget.year,
    );
  }

  Budget toDomain() {
    return Budget(
      id: id,
      familyId: familyId,
      monthlyBudget: monthlyBudget,
      month: month,
      year: year,
    );
  }
}
