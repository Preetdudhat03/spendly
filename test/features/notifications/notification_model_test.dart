import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';

void main() {
  group('Notification Model Tests', () {
    test('NotificationType parsing and category classification', () {
      expect(NotificationType.fromString('expense_added'), NotificationType.expenseAdded);
      expect(NotificationType.fromString('expense_updated'), NotificationType.expenseUpdated);
      expect(NotificationType.fromString('expense_deleted'), NotificationType.expenseDeleted);
      expect(NotificationType.fromString('budget_warning'), NotificationType.budgetWarning);
      expect(NotificationType.fromString('budget_critical'), NotificationType.budgetCritical);
      expect(NotificationType.fromString('budget_exceeded'), NotificationType.budgetExceeded);
      expect(NotificationType.fromString('family_member_joined'), NotificationType.familyMemberJoined);
      expect(NotificationType.fromString('family_member_left'), NotificationType.familyMemberLeft);
      expect(NotificationType.fromString('expense_reminder'), NotificationType.expenseReminder);
      expect(NotificationType.fromString('spending_insight'), NotificationType.spendingInsight);
      expect(NotificationType.fromString('unknown_random_type'), NotificationType.expenseAdded);

      expect(NotificationType.expenseAdded.category, NotificationCategory.expense);
      expect(NotificationType.budgetWarning.category, NotificationCategory.budget);
      expect(NotificationType.familyMemberJoined.category, NotificationCategory.family);
      expect(NotificationType.expenseReminder.category, NotificationCategory.reminder);
      expect(NotificationType.spendingInsight.category, NotificationCategory.insight);
      expect(NotificationType.syncCompleted.category, NotificationCategory.system);
    });

    test('SpendlyNotification JSON serialization and deserialization', () {
      final now = DateTime(2026, 10, 1, 12, 0, 0);
      final notification = SpendlyNotification(
        id: 'notif_1',
        userId: 'user_123',
        familyId: 'fam_456',
        type: NotificationType.expenseAdded,
        title: 'New Expense Added 💸',
        body: 'Preet added ₹250 for Petrol.',
        payload: {'expense_id': 'exp_1', 'amount': 250.0},
        isRead: false,
        priority: NotificationPriority.high,
        deepLink: '/expenses',
        notificationKey: 'expense_added:exp_1',
        createdBy: 'user_123',
        createdAt: now,
      );

      final json = notification.toJson();
      expect(json['id'], 'notif_1');
      expect(json['user_id'], 'user_123');
      expect(json['family_id'], 'fam_456');
      expect(json['type'], 'expense_added');
      expect(json['priority'], 'high');
      expect(json['notification_key'], 'expense_added:exp_1');

      final fromJson = SpendlyNotification.fromJson(json);
      expect(fromJson.id, notification.id);
      expect(fromJson.userId, notification.userId);
      expect(fromJson.familyId, notification.familyId);
      expect(fromJson.type, notification.type);
      expect(fromJson.title, notification.title);
      expect(fromJson.body, notification.body);
      expect(fromJson.payload['amount'], 250.0);
      expect(fromJson.isRead, false);
      expect(fromJson.priority, NotificationPriority.high);
      expect(fromJson.deepLink, '/expenses');
      expect(fromJson.notificationKey, 'expense_added:exp_1');
      expect(fromJson.createdAt, now);
    });

    test('SpendlyNotification handles malformed and missing payload gracefully', () {
      final json = <String, dynamic>{
        'id': 'notif_bad',
        'type': 'non_existent_type',
        'created_at': '2026-10-01T12:00:00.000Z',
      };

      final notification = SpendlyNotification.fromJson(json);
      expect(notification.id, 'notif_bad');
      expect(notification.type, NotificationType.expenseAdded);
      expect(notification.title, '');
      expect(notification.body, '');
      expect(notification.isRead, false);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('NotificationPreferences serialization and copyWith', () {
      const defaultPrefs = NotificationPreferences();
      expect(defaultPrefs.pushEnabled, true);
      expect(defaultPrefs.expenseAlerts, true);
      expect(defaultPrefs.budgetAlerts, true);
      expect(defaultPrefs.expenseReminders, false);
      expect(defaultPrefs.reminderTime, '20:00');

      final updated = defaultPrefs.copyWith(
        pushEnabled: false,
        expenseReminders: true,
        reminderTime: '21:30',
      );

      expect(updated.pushEnabled, false);
      expect(updated.expenseReminders, true);
      expect(updated.reminderTime, '21:30');

      final json = updated.toJson();
      final fromJson = NotificationPreferences.fromJson(json);
      expect(fromJson.pushEnabled, false);
      expect(fromJson.expenseReminders, true);
      expect(fromJson.reminderTime, '21:30');
    });
  });
}
