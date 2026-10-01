import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/providers/notification_providers.dart';

void main() {
  group('NotificationsState Logic Tests', () {
    final notif1 = SpendlyNotification(
      id: '1',
      userId: 'user_1',
      familyId: 'fam_1',
      type: NotificationType.expenseAdded,
      title: 'Expense Added',
      body: 'Coffee ₹120',
      isRead: false,
      createdAt: DateTime(2026, 10, 1, 10, 0),
    );

    final notif2 = SpendlyNotification(
      id: '2',
      userId: 'user_1',
      familyId: 'fam_1',
      type: NotificationType.budgetWarning,
      title: 'Budget Alert',
      body: '80% reached',
      isRead: true,
      createdAt: DateTime(2026, 10, 1, 11, 0),
    );

    final notif3 = SpendlyNotification(
      id: '3',
      userId: 'user_1',
      familyId: 'fam_1',
      type: NotificationType.familyMemberJoined,
      title: 'Family Update',
      body: 'Member joined',
      isRead: false,
      createdAt: DateTime(2026, 10, 1, 12, 0),
    );

    test('unreadCount computes correctly', () {
      final state = NotificationsState(
        isLoading: false,
        notifications: [notif1, notif2, notif3],
      );

      expect(state.unreadCount, 2);
    });

    test('filteredNotifications respects onlyUnread flag', () {
      var state = NotificationsState(
        isLoading: false,
        notifications: [notif1, notif2, notif3],
        onlyUnread: true,
      );

      expect(state.filteredNotifications.length, 2);
      expect(state.filteredNotifications.map((n) => n.id), containsAll(['1', '3']));
    });

    test('filteredNotifications filters by selectedCategory', () {
      final state = NotificationsState(
        isLoading: false,
        notifications: [notif1, notif2, notif3],
        selectedCategory: NotificationCategory.budget,
      );

      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.id, '2');
    });

    test('filteredNotifications combines onlyUnread and selectedCategory', () {
      final state = NotificationsState(
        isLoading: false,
        notifications: [notif1, notif2, notif3],
        selectedCategory: NotificationCategory.budget,
        onlyUnread: true,
      );

      // notif2 is budget category but read, so result is empty
      expect(state.filteredNotifications.isEmpty, true);
    });

    test('copyWith updates state properties immutably', () {
      final initial = NotificationsState.initial();
      expect(initial.isLoading, false);
      expect(initial.notifications, isEmpty);

      final updated = initial.copyWith(
        isLoading: true,
        notifications: [notif1],
        selectedCategory: NotificationCategory.expense,
        onlyUnread: true,
      );

      expect(updated.isLoading, true);
      expect(updated.notifications.length, 1);
      expect(updated.selectedCategory, NotificationCategory.expense);
      expect(updated.onlyUnread, true);

      final clearedCategory = updated.copyWith(clearCategory: true);
      expect(clearedCategory.selectedCategory, isNull);
    });
  });
}
