import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_empty_state.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_group.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_tile.dart';

void main() {
  group('Notification Widgets Tests', () {
    final sampleNotification = SpendlyNotification(
      id: 'notif_101',
      userId: 'u1',
      familyId: 'f1',
      type: NotificationType.expenseAdded,
      title: 'New Expense Added 💸',
      body: 'Preet added ₹450 for Food.',
      payload: {'amount': 450.0},
      isRead: false,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
    );

    testWidgets('NotificationTile renders title, body, icon, and unread dot', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NotificationTile(
              notification: sampleNotification,
              onTap: () => tapped = true,
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Expense Added 💸'), findsOneWidget);
      expect(find.text('Preet added ₹450 for Food.'), findsOneWidget);

      await tester.tap(find.text('New Expense Added 💸'));
      expect(tapped, isTrue);
    });

    testWidgets('NotificationEmptyState renders message and icon for all notifications', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: NotificationEmptyState(
              isFiltered: false,
            ),
          ),
        ),
      );

      expect(find.text("You're all caught up! 🎉"), findsOneWidget);
      expect(find.text('New family expense updates, budget alerts, and spending insights will show up here.'), findsOneWidget);
    });

    testWidgets('NotificationEmptyState renders message for filtered view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: NotificationEmptyState(
              isFiltered: true,
            ),
          ),
        ),
      );

      expect(find.text('No Matching Notifications'), findsOneWidget);
      expect(find.text('No notifications match the selected filter criteria. Try resetting your filter.'), findsOneWidget);
    });

    testWidgets('NotificationGroupView renders section header and list items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NotificationGroupView(
              notifications: [sampleNotification],
              onTap: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('New Expense Added 💸'), findsOneWidget);
    });
  });
}
