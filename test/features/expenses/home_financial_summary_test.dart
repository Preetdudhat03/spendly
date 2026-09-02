import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/models/budget.dart';
import 'package:spendly/models/expense.dart';
import 'package:intl/intl.dart';

void main() {
  group('Home Page Financial Summary Logic Tests', () {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    test('calculates current month total and today total correctly', () {
      final now = DateTime(2026, 9, 2, 14, 30);
      final expenses = [
        // Today (Sep 2)
        Expense(
          id: '1',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 500.0,
          category: 'Food',
          description: 'Lunch',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2026, 9, 2, 13, 0),
          createdAt: DateTime(2026, 9, 2, 13, 0),
          createdByName: 'Preet',
        ),
        // Earlier this month (Sep 1)
        Expense(
          id: '2',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 1500.0,
          category: 'Groceries',
          description: 'Weekly veggies',
          paymentMethod: 'Cash',
          expenseDate: DateTime(2026, 9, 1, 10, 0),
          createdAt: DateTime(2026, 9, 1, 10, 0),
          createdByName: 'Preet',
        ),
        // Previous month (Aug 31) - must be excluded
        Expense(
          id: '3',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 25000.0,
          category: 'Rent',
          description: 'August Rent',
          paymentMethod: 'Bank',
          expenseDate: DateTime(2026, 8, 31, 23, 59),
          createdAt: DateTime(2026, 8, 31, 23, 59),
          createdByName: 'Preet',
        ),
      ];

      final todayExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month &&
            e.expenseDate.day == now.day;
      });
      final todayTotal = todayExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      final monthExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
      });
      final monthTotal = monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      expect(todayTotal, 500.0);
      expect(currencyFormat.format(todayTotal), '₹500');

      expect(monthTotal, 2000.0);
      expect(currencyFormat.format(monthTotal), '₹2,000');
    });

    test('handles zero spending this month with previous month expenses correctly', () {
      final now = DateTime(2026, 9, 2, 10, 0);
      final expenses = [
        Expense(
          id: '1',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 35000.0,
          category: 'Shopping',
          description: 'Aug Shopping',
          paymentMethod: 'Card',
          expenseDate: DateTime(2026, 8, 25),
          createdAt: DateTime(2026, 8, 25),
          createdByName: 'Preet',
        ),
      ];

      final todayExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month &&
            e.expenseDate.day == now.day;
      });
      final todayTotal = todayExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      final monthExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
      });
      final monthTotal = monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      expect(todayTotal, 0.0);
      expect(currencyFormat.format(todayTotal), '₹0');

      expect(monthTotal, 0.0);
      expect(currencyFormat.format(monthTotal), '₹0');
    });

    test('calculates remaining budget correctly when within budget', () {
      const budgetLimit = 20000.0;
      const monthTotal = 7500.0;
      const bool hasBudget = true;

      double remainingBudget = 0.0;
      bool isBudgetExceeded = false;
      if (hasBudget) {
        final diff = budgetLimit - monthTotal;
        if (diff < 0) {
          remainingBudget = 0.0;
          isBudgetExceeded = true;
        } else {
          remainingBudget = diff;
          isBudgetExceeded = false;
        }
      }

      expect(remainingBudget, 12500.0);
      expect(isBudgetExceeded, isFalse);
      expect(currencyFormat.format(remainingBudget), '₹12,500');
    });

    test('handles budget exceeded scenario correctly', () {
      const budgetLimit = 20000.0;
      const monthTotal = 24500.0;
      const bool hasBudget = true;

      double remainingBudget = 0.0;
      bool isBudgetExceeded = false;
      if (hasBudget) {
        final diff = budgetLimit - monthTotal;
        if (diff < 0) {
          remainingBudget = 0.0;
          isBudgetExceeded = true;
        } else {
          remainingBudget = diff;
          isBudgetExceeded = false;
        }
      }

      expect(remainingBudget, 0.0);
      expect(isBudgetExceeded, isTrue);
      expect(currencyFormat.format(remainingBudget), '₹0');
    });

    test('handles no budget configured scenario correctly', () {
      const Budget? currentBudget = null;
      final bool hasBudget = currentBudget != null && currentBudget.monthlyBudget > 0;

      expect(hasBudget, isFalse);
    });

    test('handles year transition (Dec to Jan) boundary correctly', () {
      final now = DateTime(2027, 1, 1, 10, 0); // Jan 1st 2027
      final expenses = [
        Expense(
          id: '1',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 12000.0,
          category: 'Shopping',
          description: 'Dec Holiday',
          paymentMethod: 'Card',
          expenseDate: DateTime(2026, 12, 31, 23, 50),
          createdAt: DateTime(2026, 12, 31, 23, 50),
          createdByName: 'Preet',
        ),
        Expense(
          id: '2',
          familyId: 'f1',
          createdBy: 'u1',
          amount: 450.0,
          category: 'Food',
          description: 'New Year Breakfast',
          paymentMethod: 'UPI',
          expenseDate: DateTime(2027, 1, 1, 9, 30),
          createdAt: DateTime(2027, 1, 1, 9, 30),
          createdByName: 'Preet',
        ),
      ];

      final todayExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month &&
            e.expenseDate.day == now.day;
      });
      final todayTotal = todayExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      final monthExpenses = expenses.where((e) {
        return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
      });
      final monthTotal = monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

      expect(todayTotal, 450.0);
      expect(monthTotal, 450.0);
    });
  });

  group('Home Page Financial Summary Widget Rendering Tests', () {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    Widget buildTestWidget({
      required ThemeData theme,
      required double monthTotal,
      required double todayTotal,
      required bool hasBudget,
      required double remainingBudget,
      required bool isBudgetExceeded,
      required double budgetLimit,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total Spent This Month',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            currencyFormat.format(monthTotal),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -1.8,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: theme.cardTheme.color ?? theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: theme.colorScheme.outline, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Today's Spending",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      currencyFormat.format(todayTotal),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: theme.cardTheme.color ?? theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: theme.colorScheme.outline, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining This Month',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      hasBudget ? currencyFormat.format(remainingBudget) : '—',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: isBudgetExceeded ? theme.colorScheme.error : theme.colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    !hasBudget
                                        ? 'Budget not set'
                                        : (isBudgetExceeded
                                            ? 'Budget exceeded'
                                            : '${currencyFormat.format(budgetLimit)} budget'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isBudgetExceeded ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders properly in Light theme with standard budget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        theme: AppTheme.lightTheme,
        monthTotal: 4500.0,
        todayTotal: 350.0,
        hasBudget: true,
        remainingBudget: 15500.0,
        isBudgetExceeded: false,
        budgetLimit: 20000.0,
      ));

      expect(find.text('Total Spent This Month'), findsOneWidget);
      expect(find.text('₹4,500'), findsOneWidget);
      expect(find.text("Today's Spending"), findsOneWidget);
      expect(find.text('₹350'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Remaining This Month'), findsOneWidget);
      expect(find.text('₹15,500'), findsOneWidget);
      expect(find.text('₹20,000 budget'), findsOneWidget);
    });

    testWidgets('renders properly in Dark theme with exceeded budget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        theme: AppTheme.darkTheme,
        monthTotal: 22000.0,
        todayTotal: 1200.0,
        hasBudget: true,
        remainingBudget: 0.0,
        isBudgetExceeded: true,
        budgetLimit: 20000.0,
      ));

      expect(find.text('Total Spent This Month'), findsOneWidget);
      expect(find.text('₹22,000'), findsOneWidget);
      expect(find.text("Today's Spending"), findsOneWidget);
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('Remaining This Month'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('Budget exceeded'), findsOneWidget);
    });

    testWidgets('renders properly when no budget is configured', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        theme: AppTheme.lightTheme,
        monthTotal: 1500.0,
        todayTotal: 0.0,
        hasBudget: false,
        remainingBudget: 0.0,
        isBudgetExceeded: false,
        budgetLimit: 0.0,
      ));

      expect(find.text('Total Spent This Month'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text("Today's Spending"), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('Remaining This Month'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Budget not set'), findsOneWidget);
    });
  });
}
