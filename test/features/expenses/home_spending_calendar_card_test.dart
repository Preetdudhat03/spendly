import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/analytics/presentation/widgets/drill_down_sheet.dart';
import 'package:spendly/features/expenses/widgets/home_spending_calendar_card.dart';
import 'package:spendly/models/expense.dart';

Expense _makeExpense({
  required String id,
  required double amount,
  required DateTime date,
  String category = 'Food',
  String description = 'Lunch',
  String createdBy = 'u1',
  String createdByName = 'Preet',
  String paymentMethod = 'UPI',
}) {
  return Expense(
    id: id,
    familyId: 'f1',
    createdBy: createdBy,
    amount: amount,
    category: category,
    description: description,
    paymentMethod: paymentMethod,
    expenseDate: date,
    createdAt: date,
    createdByName: createdByName,
  );
}

Widget _wrapWithApp({
  required Widget child,
  ThemeData? theme,
  Size surfaceSize = const Size(400, 800),
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  group('HomeSpendingCalendarCard Tests', () {
    testWidgets('1 & 4. Renders current month/year and blocks future month navigation', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: const [],
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      expect(find.text('Monthly Spending'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);

      // Next month button should be disabled when on current month
      final nextBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(nextBtn.onPressed, isNull);
    });

    testWidgets('2 & 3. Previous and Next month navigation works', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: const [],
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      // Go back to October 2026
      await tester.tap(find.byTooltip('Previous Month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      // Next month button should now be enabled
      final nextBtn = tester.widget<IconButton>(
        find.byTooltip('Next Month'),
      );
      expect(nextBtn.onPressed, isNotNull);

      // Navigate forward back to November 2026
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('5 & 6. Sunday-first weekday headers and February leap-year handling', (tester) async {
      final refNow = DateTime(2026, 11, 24);

      // Leap year: February 2024 has 29 days
      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: const [],
            currencyFormat: currencyFormat,
            initialMonth: DateTime(2024, 2, 10),
            referenceNow: refNow,
          ),
        ),
      );

      expect(find.text('February 2024'), findsOneWidget);
      // Weekday headers S M T W T F S
      expect(find.text('S'), findsNWidgets(2));
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);

      // Non-leap year: February 2026 has 28 days
      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: const [],
            currencyFormat: currencyFormat,
            initialMonth: DateTime(2026, 2, 10),
            referenceNow: refNow,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('February 2026'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('29'), findsNothing);
    });

    testWidgets('7, 8, 9, 10 & 11. Aggregates all family expenses, calculates total/avg/peak, and hides zero labels', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      final expenses = [
        // User 1 on Nov 6
        _makeExpense(
          id: 'e1',
          amount: 2000.0,
          date: DateTime(2026, 11, 6, 10, 0),
          createdBy: 'u1',
          createdByName: 'Preet',
          description: 'Groceries',
        ),
        // User 2 on Nov 6 (must be included - family-wide)
        _makeExpense(
          id: 'e2',
          amount: 1000.0,
          date: DateTime(2026, 11, 6, 14, 0),
          createdBy: 'u2',
          createdByName: 'Meeta',
          description: 'Electricity',
        ),
        // Nov 10
        _makeExpense(
          id: 'e3',
          amount: 300.0,
          date: DateTime(2026, 11, 10, 9, 0),
          createdBy: 'u1',
          createdByName: 'Preet',
          description: 'Coffee',
        ),
        // Previous month (Oct 2026) - excluded from Nov totals
        _makeExpense(
          id: 'e4',
          amount: 9999.0,
          date: DateTime(2026, 10, 20, 9, 0),
          createdBy: 'u1',
          createdByName: 'Preet',
          description: 'Old Expense',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: expenses,
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      // Total Spent = 2000 + 1000 + 300 = ₹3,300
      expect(find.text('₹3,300'), findsOneWidget);
      // Daily Avg = 3300 / 30 = ₹110
      expect(find.text('₹110'), findsOneWidget);
      // Peak Day = 6 Nov (₹3,000)
      expect(find.text('6 Nov (₹3,000)'), findsOneWidget);
      // Cell amounts on day 6 and day 10
      expect(find.text('₹3,000'), findsOneWidget);
      expect(find.text('₹300'), findsOneWidget);
      // Days without expenses must NOT show ₹0
      expect(find.text('₹0'), findsNothing);
    });

    testWidgets('12 & 13. Tapping a day with expenses highlights it and opens DrillDownSheet', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      final expenses = [
        _makeExpense(
          id: 'e1',
          amount: 450.0,
          date: DateTime(2026, 11, 6, 12, 30),
          description: 'Family Lunch',
          createdByName: 'Preet',
        ),
        _makeExpense(
          id: 'e2',
          amount: 150.0,
          date: DateTime(2026, 11, 6, 18, 0),
          description: 'Snacks',
          createdByName: 'Meeta',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: expenses,
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(find.byType(DrillDownSheet), findsOneWidget);
      expect(find.text('Friday, 6 November 2026'), findsOneWidget);
      expect(find.text('Family Lunch'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);
    });

    testWidgets('14. Tapping an empty day opens empty day sheet', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      await tester.pumpWidget(
        _wrapWithApp(
          child: HomeSpendingCalendarCard(
            expenses: const [],
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(find.text('No expenses on this day'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('15. Large currency values render cleanly on narrow phone width without overflow', (tester) async {
      final refNow = DateTime(2026, 11, 24);
      final expenses = [
        _makeExpense(
          id: 'e1',
          amount: 29590.27,
          date: DateTime(2026, 11, 6, 12, 0),
          description: 'Rent',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          surfaceSize: const Size(320, 640),
          child: HomeSpendingCalendarCard(
            expenses: expenses,
            currencyFormat: currencyFormat,
            initialMonth: refNow,
            referenceNow: refNow,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('₹29.6k'), findsOneWidget);
    });

    testWidgets('16, 17 & 18. Renders empty month state in both Light and Dark themes', (tester) async {
      final refNow = DateTime(2026, 11, 24);

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          _wrapWithApp(
            theme: theme,
            child: HomeSpendingCalendarCard(
              expenses: const [],
              currencyFormat: currencyFormat,
              initialMonth: refNow,
              referenceNow: refNow,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Monthly Spending'), findsOneWidget);
        // Total Spent & Daily Avg are ₹0, Peak Day is —
        expect(find.text('₹0'), findsNWidgets(2));
        expect(find.text('—'), findsOneWidget);
      }
    });
  });
}
