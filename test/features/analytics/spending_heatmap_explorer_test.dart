import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/analytics/presentation/widgets/spending_heatmap_explorer.dart';
import 'package:spendly/models/expense.dart';

void main() {
  final testDateJul18 = DateTime(2026, 7, 18, 14, 30);
  final testDateJul19 = DateTime(2026, 7, 19, 10, 00);
  final testDateDec31 = DateTime(2026, 12, 31, 22, 00);
  final testDateJan01 = DateTime(2027, 1, 1, 09, 00);

  final mockExpenses = [
    Expense(
      id: 'e1',
      familyId: 'fam1',
      createdBy: 'user_preet',
      createdByName: 'Preet',
      amount: 1200.0,
      category: 'Food',
      description: 'Dinner with family',
      paymentMethod: 'UPI',
      expenseDate: testDateJul18,
      createdAt: testDateJul18,
    ),
    Expense(
      id: 'e2',
      familyId: 'fam1',
      createdBy: 'user_meeta',
      createdByName: 'Meeta',
      amount: 1250.0,
      category: 'Groceries',
      description: 'Supermarket',
      paymentMethod: 'Card',
      expenseDate: testDateJul18,
      createdAt: testDateJul18,
    ),
    Expense(
      id: 'e3',
      familyId: 'fam1',
      createdBy: 'user_preet',
      createdByName: 'Preet',
      amount: 500.0,
      category: 'Fuel',
      description: 'Petrol',
      paymentMethod: 'UPI',
      expenseDate: testDateJul19,
      createdAt: testDateJul19,
    ),
    Expense(
      id: 'e4',
      familyId: 'fam1',
      createdBy: 'user_preet',
      createdByName: 'Preet',
      amount: 3000.0,
      category: 'Shopping',
      description: 'Year-end sale',
      paymentMethod: 'Card',
      expenseDate: testDateDec31,
      createdAt: testDateDec31,
    ),
    Expense(
      id: 'e5',
      familyId: 'fam1',
      createdBy: 'user_meeta',
      createdByName: 'Meeta',
      amount: 800.0,
      category: 'Coffee',
      description: 'New year cafe',
      paymentMethod: 'Cash',
      expenseDate: testDateJan01,
      createdAt: testDateJan01,
    ),
  ];

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('SpendingHeatmapExplorer Tests', () {
    testWidgets('Renders Year View initially with correct totals and month tiles', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SpendingHeatmapExplorer(
            expenses: mockExpenses,
            initialYear: 2026,
          ),
        ),
      );

      // Verify Year View header
      expect(find.text('2026'), findsWidgets);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Monthly Avg'), findsOneWidget);

      // Verify 12 month tiles (Jan to Dec)
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });

    testWidgets('Drill-down: Year View -> Tap July -> Month View -> Tap July 18 -> Day View', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SpendingHeatmapExplorer(
            expenses: mockExpenses,
            initialYear: 2026,
          ),
        ),
      );

      // Tap on July tile
      await tester.tap(find.text('Jul'));
      await tester.pumpAndSettle();

      // Should be in Month View for July 2026
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Daily Avg'), findsOneWidget);
      expect(find.text('Peak Day'), findsOneWidget);

      // Tap on day 18 in calendar
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();

      // Should be in Day View for July 18, 2026
      expect(find.text('Jul 18, 2026'), findsOneWidget);
      expect(find.text('2 transactions recorded'), findsOneWidget);
      expect(find.text('₹2,450'), findsOneWidget); // 1200 + 1250
      expect(find.text('Preet'), findsWidgets);
      expect(find.text('Meeta'), findsWidgets);
      expect(find.text('Dinner with family'), findsOneWidget);
      expect(find.text('Supermarket'), findsOneWidget);
    });

    testWidgets('Drill-up: Day View -> Tap breadcrumb July -> Month View -> Tap breadcrumb 2026 -> Year View', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SpendingHeatmapExplorer(
            expenses: mockExpenses,
            initialYear: 2026,
          ),
        ),
      );

      // Drill down to July 18
      await tester.tap(find.text('Jul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();

      expect(find.text('Jul 18, 2026'), findsOneWidget);

      // Tap 'July' breadcrumb
      await tester.tap(find.text('July'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);

      // Tap '2026' breadcrumb
      await tester.tap(find.text('2026').first);
      await tester.pumpAndSettle();

      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
    });

    testWidgets('Month navigation across year boundaries: Dec 2026 -> Next Month -> Jan 2027', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SpendingHeatmapExplorer(
            expenses: mockExpenses,
            initialYear: 2026,
          ),
        ),
      );

      // Drill down to December 2026
      await tester.tap(find.text('Dec'));
      await tester.pumpAndSettle();

      expect(find.text('December 2026'), findsOneWidget);

      // Tap Next Month arrow
      await tester.tap(find.bySemanticsLabel('Next Month'));
      await tester.pumpAndSettle();

      // Should move to January 2027
      expect(find.text('January 2027'), findsOneWidget);
      expect(find.text('2027'), findsWidgets);
    });

    testWidgets('Empty Year displays empty state with lowest intensity tiles without error', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SpendingHeatmapExplorer(
            expenses: [],
            initialYear: 2026,
          ),
        ),
      );

      expect(find.text('2026'), findsWidgets);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets);
    });
  });
}
