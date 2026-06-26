import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/utils/ai_insights.dart';
import 'package:spendly/core/services/suggestions_service.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

void main() {
  group('AI Insights Heuristics Tests', () {
    test('generate returns a notice when budget exceeds 70%', () {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          familyId: 'fam_1',
          createdBy: 'user_1',
          amount: 8000.0,
          category: 'Food',
          description: 'Dinner',
          paymentMethod: 'UPI',
          expenseDate: now,
          createdAt: now,
          createdByName: 'Dad',
        ),
      ];

      // Budget limit is 10,000, spend is 8,000 (80%)
      final insights = AiInsights.generate(expenses, 10000.0);

      expect(insights.any((item) => item.contains('used 80%')), isTrue);
      expect(insights.any((item) => item.contains('Budget notice')), isTrue);
    });

    test('generate returns a warning when budget exceeds 90%', () {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          familyId: 'fam_1',
          createdBy: 'user_1',
          amount: 9500.0,
          category: 'Rent',
          description: 'Flat rent',
          paymentMethod: 'Card',
          expenseDate: now,
          createdAt: now,
          createdByName: 'Dad',
        ),
      ];

      // Budget limit is 10,000, spend is 9,500 (95%)
      final insights = AiInsights.generate(expenses, 10000.0);

      expect(insights.any((item) => item.contains('used 95%')), isTrue);
      expect(insights.any((item) => item.contains('Budget warning')), isTrue);
    });
  });

  group('Smart Suggestions Service Tests', () {
    test('generateSuggestions identifies recurring patterns', () {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          familyId: 'fam_1',
          createdBy: 'user_1',
          amount: 60.0,
          category: 'Food',
          description: 'Milk',
          paymentMethod: 'UPI',
          expenseDate: now,
          createdAt: now,
          createdByName: 'Dad',
        ),
        Expense(
          id: '2',
          familyId: 'fam_1',
          createdBy: 'user_1',
          amount: 60.0,
          category: 'Food',
          description: 'Milk',
          paymentMethod: 'UPI',
          expenseDate: now.subtract(const Duration(days: 1)),
          createdAt: now,
          createdByName: 'Dad',
        ),
        Expense(
          id: '3',
          familyId: 'fam_1',
          createdBy: 'user_1',
          amount: 500.0,
          category: 'Petrol',
          description: 'Fuel',
          paymentMethod: 'Cash',
          expenseDate: now,
          createdAt: now,
          createdByName: 'Dad',
        ),
      ];

      final suggestions = SuggestionsService.generateSuggestions(expenses);

      // Should identify "Milk" as recurring because it appears twice with same description & amount
      expect(suggestions.length, 1);
      expect(suggestions[0].description, 'Milk');
      expect(suggestions[0].amount, 60.0);
    });
  });

  group('Analytics Model Tests', () {
    test('CategoryShare calculates correct properties', () {
      final share = CategoryShare(
        category: 'Food',
        amount: 1500.0,
        percentage: 30.0,
        prevAmount: 1000.0,
        diffPercent: 50.0,
        isIncrease: true,
      );
      expect(share.category, 'Food');
      expect(share.amount, 1500.0);
      expect(share.percentage, 30.0);
      expect(share.diffPercent, 50.0);
      expect(share.isIncrease, isTrue);
    });
  });
}
