import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/analytics/models/analytics_models.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';

void main() {
  group('Analytics Engine Phase 1 Deterministic Tests', () {
    test('Calculates aggregation and compatibility fields deterministically', () {
      final now = DateTime(2026, 8, 20); // Fixed date for deterministic results
      
      final expenses = [
        ExpenseAnalyticsInput(
          id: '1',
          amount: 1000,
          category: 'Food',
          description: 'Groceries',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2026, 8, 15, 10, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
        ExpenseAnalyticsInput(
          id: '2',
          amount: 500,
          category: 'Food',
          description: 'Snacks',
          paymentMethod: 'Cash',
          expenseDate: DateTime(2026, 8, 16, 14, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
        ExpenseAnalyticsInput(
          id: '3',
          amount: 3000,
          category: 'Shopping',
          description: 'Clothes',
          paymentMethod: 'Card',
          expenseDate: DateTime(2026, 8, 18, 18, 0),
          createdBy: 'user2',
          createdByName: 'Meeta',
        ),
        // Previous month expense
        ExpenseAnalyticsInput(
          id: '4',
          amount: 2000,
          category: 'Shopping',
          description: 'Shoes',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2026, 7, 15, 12, 0),
          createdBy: 'user2',
          createdByName: 'Meeta',
        ),
      ];

      final originalExpenses = {
        '1': Expense(id: '1', familyId: 'f1', createdBy: 'user1', amount: 1000, category: 'Food', description: 'Groceries', paymentMethod: 'UPI', expenseDate: DateTime(2026, 8, 15, 10, 0), createdAt: now, createdByName: 'Preet'),
        '2': Expense(id: '2', familyId: 'f1', createdBy: 'user1', amount: 500, category: 'Food', description: 'Snacks', paymentMethod: 'Cash', expenseDate: DateTime(2026, 8, 16, 14, 0), createdAt: now, createdByName: 'Preet'),
        '3': Expense(id: '3', familyId: 'f1', createdBy: 'user2', amount: 3000, category: 'Shopping', description: 'Clothes', paymentMethod: 'Card', expenseDate: DateTime(2026, 8, 18, 18, 0), createdAt: now, createdByName: 'Meeta'),
        '4': Expense(id: '4', familyId: 'f1', createdBy: 'user2', amount: 2000, category: 'Shopping', description: 'Shoes', paymentMethod: 'UPI', expenseDate: DateTime(2026, 7, 15, 12, 0), createdAt: now, createdByName: 'Meeta'),
      };

      final input = AnalyticsInput(
        expenses: expenses,
        budgetLimit: 10000,
        activeMembersCount: 2,
        filterTypeIndex: AnalyticsFilterType.thisMonth.index, // thisMonth
        customRange: null,
        memberIdToName: {'user1': 'Preet', 'user2': 'Meeta'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );

      // Run calculation in same isolate for test
      final result = AnalyticsNotifier.runCalculations(input);
      
      expect(result.confidence, DataConfidence.low); // < 5 expenses
      
      final state = AnalyticsState.fromResult(result, originalExpenses);
      
      expect(state.totalSpent, 4500.0);
      expect(state.prevTotalSpent, 2000.0);
      expect(state.totalTransactions, 3);
      expect(state.prevTotalTransactions, 1);
      
      // Category Checks
      expect(state.categoryShares.length, 2);
      final shoppingShare = state.categoryShares.firstWhere((c) => c.category == 'Shopping');
      expect(shoppingShare.amount, 3000.0);
      expect(shoppingShare.prevAmount, 2000.0);
      expect(shoppingShare.isIncrease, true);
      
      final foodShare = state.categoryShares.firstWhere((c) => c.category == 'Food');
      expect(foodShare.amount, 1500.0);
      expect(foodShare.prevAmount, 0.0);
      
      // Member Checks
      expect(state.memberShares.length, 2);
      final meetaShare = state.memberShares.firstWhere((m) => m.name == 'Meeta');
      expect(meetaShare.totalSpent, 3000.0);
      expect(meetaShare.favoriteCategory, 'Shopping');
      
      // Payment Checks
      final upiShare = state.paymentMethodShares.firstWhere((p) => p.method == 'UPI');
      expect(upiShare.amount, 1000.0); // Only current month UPI
      
      // Phase 2: Executive Summary & Equivalent Period Checks
      expect(state.summary, isNotNull);
      // current spent: 4500 (Aug)
      // prev spent: 2000 (July)
      // Since 'now' is Aug 20, equivalent prev is July 1 - July 20.
      // The test has a July expense on July 15 for 2000.
      // So equivalentPrevTotalSpent is 2000.
      expect(state.summary!.totalSpend.currentValue, 4500.0);
      expect(state.summary!.totalSpend.previousValue, 2000.0);
      expect(state.summary!.totalSpend.absoluteChange, 2500.0);
      expect(state.summary!.totalSpend.percentageChange, 125.0); // (2500 / 2000) * 100
      expect(state.summary!.totalSpend.direction, TrendDirection.increase);
      
      // Phase 6: Health Score Checks
      expect(state.healthScore, isNotNull);
      expect(state.healthScore!.budgetAdherence, 100); // 4500 < 10000 limit
      expect(state.healthScore!.dataConfidenceScore, 30); // Low confidence mapped to 30
      
      // Phase 4: Diagnostic Intelligence
      expect(state.diagnostic, isNotNull);
      expect(state.diagnostic!.categoryInsights.length, 2);
      expect(state.diagnostic!.topCategoryShare, (3000 / 4500) * 100);
      expect(state.diagnostic!.primaryIncreaseContributor, 'Food'); // 1500 increase vs Shopping 1000 increase
      expect(state.diagnostic!.smallPurchasesCount, 0); // test data min is 500
      
      // Phase 5: Pattern Intelligence
      expect(state.patterns, isNotNull);
      expect(state.patterns!.consistency.level, isNot(ConsistencyLevel.unavailable));
      expect(state.patterns!.highSpendingDays.length, 2); // 2 distinct days in test data hit the threshold
      // Has historical expenses & current period checks
      expect(state.hasHistoricalExpenses, true);
      expect(state.hasExpensesInCurrentPeriod, true);
      expect(state.totalHistoricalExpensesCount, 4);
      expect(state.status, AnalyticsStatus.success);
    });

    test('Scenario A: Historical expenses exist, current month has 0 expenses (e.g. September 1st)', () {
      final now = DateTime(2026, 9, 1);
      final augustExpenses = List.generate(
        15,
        (i) => ExpenseAnalyticsInput(
          id: 'aug_$i',
          amount: 200,
          category: 'Food',
          description: 'Food $i',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2026, 8, i + 1, 12, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
      );

      final originalExpenses = {
        for (var e in augustExpenses)
          e.id: Expense(
            id: e.id,
            familyId: 'f1',
            createdBy: e.createdBy,
            amount: e.amount,
            category: e.category,
            description: e.description,
            paymentMethod: e.paymentMethod,
            expenseDate: e.expenseDate,
            createdAt: now,
            createdByName: e.createdByName,
          ),
      };

      final input = AnalyticsInput(
        expenses: augustExpenses,
        budgetLimit: 20000,
        activeMembersCount: 1,
        filterTypeIndex: AnalyticsFilterType.thisMonth.index, // September
        customRange: null,
        memberIdToName: {'user1': 'Preet'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );

      final result = AnalyticsNotifier.runCalculations(input);
      final state = AnalyticsState.fromResult(result, originalExpenses);

      // Must identify historical data exists while current period is empty
      expect(state.hasHistoricalExpenses, true);
      expect(state.hasExpensesInCurrentPeriod, false);
      expect(state.totalHistoricalExpensesCount, 15);
      expect(state.status, AnalyticsStatus.success); // NOT AnalyticsStatus.empty!
      expect(state.totalSpent, 0.0);
      expect(state.totalTransactions, 0);
      expect(state.filteredExpenses.isEmpty, true);
      expect(state.prevTotalSpent, 3000.0); // 15 * 200 from August
      expect(state.prevTotalTransactions, 15);
    });

    test('Scenario B: Historical expenses exist, filter set to August contains expenses', () {
      final now = DateTime(2026, 9, 1);
      final augustExpenses = List.generate(
        15,
        (i) => ExpenseAnalyticsInput(
          id: 'aug_$i',
          amount: 200,
          category: 'Food',
          description: 'Food $i',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2026, 8, i + 1, 12, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
      );

      final originalExpenses = {
        for (var e in augustExpenses)
          e.id: Expense(
            id: e.id,
            familyId: 'f1',
            createdBy: e.createdBy,
            amount: e.amount,
            category: e.category,
            description: e.description,
            paymentMethod: e.paymentMethod,
            expenseDate: e.expenseDate,
            createdAt: now,
            createdByName: e.createdByName,
          ),
      };

      final input = AnalyticsInput(
        expenses: augustExpenses,
        budgetLimit: 20000,
        activeMembersCount: 1,
        filterTypeIndex: AnalyticsFilterType.lastMonth.index, // August
        customRange: null,
        memberIdToName: {'user1': 'Preet'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );

      final result = AnalyticsNotifier.runCalculations(input);
      final state = AnalyticsState.fromResult(result, originalExpenses);

      expect(state.hasHistoricalExpenses, true);
      expect(state.hasExpensesInCurrentPeriod, true);
      expect(state.totalHistoricalExpensesCount, 15);
      expect(state.status, AnalyticsStatus.success);
      expect(state.totalSpent, 3000.0);
      expect(state.totalTransactions, 15);
    });

    test('Scenario C: Truly new user with 0 expenses in complete history', () {
      final now = DateTime(2026, 9, 1);
      final input = AnalyticsInput(
        expenses: [],
        budgetLimit: 20000,
        activeMembersCount: 1,
        filterTypeIndex: AnalyticsFilterType.thisMonth.index,
        customRange: null,
        memberIdToName: {'user1': 'Preet'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );

      final result = AnalyticsNotifier.runCalculations(input);
      final state = AnalyticsState.fromResult(result, {});

      expect(state.hasHistoricalExpenses, false);
      expect(state.hasExpensesInCurrentPeriod, false);
      expect(state.totalHistoricalExpensesCount, 0);
      expect(state.status, AnalyticsStatus.empty); // Global empty state
      expect(state.totalSpent, 0.0);
      expect(state.totalTransactions, 0);
    });

    test('Scenario D: User has historical expenses, but filters by a member with 0 expenses', () {
      final now = DateTime(2026, 9, 1);
      final expenses = [
        ExpenseAnalyticsInput(
          id: '1',
          amount: 500,
          category: 'Food',
          description: 'Snacks',
          paymentMethod: 'Cash',
          expenseDate: DateTime(2026, 9, 1, 10, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
      ];

      final originalExpenses = {
        '1': Expense(
          id: '1',
          familyId: 'f1',
          createdBy: 'user1',
          amount: 500,
          category: 'Food',
          description: 'Snacks',
          paymentMethod: 'Cash',
          expenseDate: DateTime(2026, 9, 1, 10, 0),
          createdAt: now,
          createdByName: 'Preet',
        ),
      };

      // Filter by 'user2' (Meeta) who has no expenses
      final input = AnalyticsInput(
        expenses: expenses,
        budgetLimit: 20000,
        activeMembersCount: 2,
        filterTypeIndex: AnalyticsFilterType.thisMonth.index,
        customRange: null,
        memberIdToName: {'user1': 'Preet', 'user2': 'Meeta'},
        selectedMemberId: 'user2',
        now: now,
        calculationVersion: 1,
      );

      final result = AnalyticsNotifier.runCalculations(input);
      final state = AnalyticsState.fromResult(result, originalExpenses);

      // Historical expenses exist in family, but Meeta has 0 in this period
      expect(state.hasHistoricalExpenses, true);
      expect(state.hasExpensesInCurrentPeriod, false);
      expect(state.totalHistoricalExpensesCount, 1);
      expect(state.status, AnalyticsStatus.success); // Not global empty state!
      expect(state.totalSpent, 0.0);
      expect(state.totalTransactions, 0);
    });

    test('Filter transitions: Changing filter never mutates hasHistoricalExpenses from true to false', () {
      final now = DateTime(2026, 9, 1);
      final augustExpenses = [
        ExpenseAnalyticsInput(
          id: 'aug_1',
          amount: 1500,
          category: 'Travel',
          description: 'Flight',
          paymentMethod: 'Card',
          expenseDate: DateTime(2026, 8, 10, 10, 0),
          createdBy: 'user1',
          createdByName: 'Preet',
        ),
      ];
      final originalExpenses = {
        'aug_1': Expense(
          id: 'aug_1',
          familyId: 'f1',
          createdBy: 'user1',
          amount: 1500,
          category: 'Travel',
          description: 'Flight',
          paymentMethod: 'Card',
          expenseDate: DateTime(2026, 8, 10, 10, 0),
          createdAt: now,
          createdByName: 'Preet',
        ),
      };

      // 1. September (0 expenses)
      final inputSep = AnalyticsInput(
        expenses: augustExpenses,
        budgetLimit: 20000,
        activeMembersCount: 1,
        filterTypeIndex: AnalyticsFilterType.thisMonth.index,
        customRange: null,
        memberIdToName: {'user1': 'Preet'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );
      final stateSep = AnalyticsState.fromResult(
        AnalyticsNotifier.runCalculations(inputSep),
        originalExpenses,
      );
      expect(stateSep.hasHistoricalExpenses, true);
      expect(stateSep.hasExpensesInCurrentPeriod, false);

      // 2. August (1 expense)
      final inputAug = AnalyticsInput(
        expenses: augustExpenses,
        budgetLimit: 20000,
        activeMembersCount: 1,
        filterTypeIndex: AnalyticsFilterType.lastMonth.index,
        customRange: null,
        memberIdToName: {'user1': 'Preet'},
        selectedMemberId: null,
        now: now,
        calculationVersion: 1,
      );
      final stateAug = AnalyticsState.fromResult(
        AnalyticsNotifier.runCalculations(inputAug),
        originalExpenses,
      );
      expect(stateAug.hasHistoricalExpenses, true);
      expect(stateAug.hasExpensesInCurrentPeriod, true);

      // 3. Back to September (0 expenses)
      final stateSep2 = AnalyticsState.fromResult(
        AnalyticsNotifier.runCalculations(inputSep),
        originalExpenses,
      );
      expect(stateSep2.hasHistoricalExpenses, true);
      expect(stateSep2.hasExpensesInCurrentPeriod, false);
    });
  });
}
