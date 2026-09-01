import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family, FamilyNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/family_member.dart';

void main() {
  Widget buildTestableWidget({
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: AnalyticsPage(),
      ),
    );
  }

  group('AnalyticsPage Empty-State and Loading Tests', () {
    testWidgets('New user with zero historical expenses displays onboarding empty state', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyState = AnalyticsState.initial(
        DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)),
        hasHistoricalExpenses: false,
        totalHistoricalExpensesCount: 0,
      ).copyWith(status: AnalyticsStatus.empty);

      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            analyticsProvider.overrideWith((ref) => _StaticAnalyticsNotifier(emptyState)),
            expenseProvider.overrideWith((ref) => _StaticExpenseNotifier(ExpenseState(expenses: [], isLoading: false))),
            familyProvider.overrideWith((ref) => _StaticFamilyNotifier(FamilyState(isLoading: false, members: []))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No expenses recorded yet'), findsOneWidget);
      expect(find.text('Add First Expense'), findsOneWidget);
      expect(find.text('Total Spent'), findsNothing);
    });

    testWidgets('User with August expenses viewing empty September displays dashboard and contextual banner', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final augExpense = Expense(
        id: '1',
        familyId: 'f1',
        createdBy: 'user1',
        amount: 500,
        category: 'Food',
        description: 'Lunch',
        paymentMethod: 'UPI',
        expenseDate: DateTime(2026, 8, 15),
        createdAt: DateTime(2026, 8, 15),
        createdByName: 'Preet',
      );

      final septemberZeroState = AnalyticsState.initial(
        DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)),
        hasHistoricalExpenses: true,
        totalHistoricalExpensesCount: 1,
      ).copyWith(
        status: AnalyticsStatus.success,
        hasHistoricalExpenses: true,
        hasExpensesInCurrentPeriod: false,
        totalHistoricalExpensesCount: 1,
        totalSpent: 0,
        totalTransactions: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            analyticsProvider.overrideWith((ref) => _StaticAnalyticsNotifier(septemberZeroState)),
            expenseProvider.overrideWith((ref) => _StaticExpenseNotifier(ExpenseState(expenses: [augExpense], isLoading: false))),
            familyProvider.overrideWith((ref) => _StaticFamilyNotifier(FamilyState(isLoading: false, members: []))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT show global onboarding empty state
      expect(find.text('No expenses recorded yet'), findsNothing);
      expect(find.text('Add First Expense'), findsNothing);

      // Must show contextual banner and dashboard elements
      expect(find.text('No expenses this month'), findsOneWidget);
      expect(find.text('No expenses were recorded during this period.'), findsOneWidget);
      expect(find.text('Total Spent'), findsWidgets);
      expect(find.text('Daily Average'), findsWidgets);
      expect(find.text('Budget Remaining'), findsWidgets);
    });

    testWidgets('Member filter with zero expenses in period displays member contextual message', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final augExpense = Expense(
        id: '1',
        familyId: 'f1',
        createdBy: 'user1',
        amount: 500,
        category: 'Food',
        description: 'Lunch',
        paymentMethod: 'UPI',
        expenseDate: DateTime(2026, 8, 15),
        createdAt: DateTime(2026, 8, 15),
        createdByName: 'Preet',
      );

      final member = FamilyMember(
        id: 'm1',
        familyId: 'f1',
        userId: 'user2',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: 'Meeta',
      );

      final memberZeroState = AnalyticsState.initial(
        DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)),
        hasHistoricalExpenses: true,
        totalHistoricalExpensesCount: 1,
      ).copyWith(
        status: AnalyticsStatus.success,
        hasHistoricalExpenses: true,
        hasExpensesInCurrentPeriod: false,
        totalHistoricalExpensesCount: 1,
        totalSpent: 0,
        totalTransactions: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            analyticsMemberFilterProvider.overrideWith((ref) => 'user2'),
            analyticsProvider.overrideWith((ref) => _StaticAnalyticsNotifier(memberZeroState)),
            expenseProvider.overrideWith((ref) => _StaticExpenseNotifier(ExpenseState(expenses: [augExpense], isLoading: false))),
            familyProvider.overrideWith((ref) => _StaticFamilyNotifier(FamilyState(isLoading: false, members: [member]))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No expenses recorded yet'), findsNothing);
      expect(find.text('Meeta has no expenses'), findsOneWidget);
      expect(find.text('Clear Filter'), findsOneWidget);
      expect(find.text('Total Spent'), findsWidgets);
    });

    testWidgets('Loading state displays shimmer skeleton rather than any empty state', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final loadingState = AnalyticsState.initial(
        DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)),
        hasHistoricalExpenses: true,
        totalHistoricalExpensesCount: 5,
      ).copyWith(status: AnalyticsStatus.loading);

      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            analyticsProvider.overrideWith((ref) => _StaticAnalyticsNotifier(loadingState)),
            expenseProvider.overrideWith((ref) => _StaticExpenseNotifier(ExpenseState(expenses: [], isLoading: true))),
            familyProvider.overrideWith((ref) => _StaticFamilyNotifier(FamilyState(isLoading: false, members: []))),
          ],
        ),
      );

      expect(find.text('No expenses recorded yet'), findsNothing);
      expect(find.text('No expenses this month'), findsNothing);
      expect(find.text('Updating analytics...'), findsOneWidget);
    });
  });
}

class _StaticAnalyticsNotifier extends StateNotifier<AnalyticsState>
    implements AnalyticsNotifier {
  _StaticAnalyticsNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StaticExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _StaticExpenseNotifier(super.state);

  @override
  Future<void> loadExpenses() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StaticFamilyNotifier extends StateNotifier<FamilyState>
    implements FamilyNotifier {
  _StaticFamilyNotifier(super.state);

  @override
  Future<void> loadMembers() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
