import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/providers/notification_providers.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';

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

    test('clearAllNotifications empties notifications and unreadCount', () {
      final state = NotificationsState(
        isLoading: false,
        notifications: [notif1, notif2, notif3],
      );
      expect(state.notifications.length, 3);
      expect(state.unreadCount, 2);

      final cleared = state.copyWith(notifications: []);
      expect(cleared.notifications, isEmpty);
      expect(cleared.unreadCount, 0);
    });
  });

  group('NotificationRepository Clear & Delete Persistence Tests', () {
    late Directory tempDir;
    late NotificationRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('spendly_notif_repo_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveService.settingsBox);
      await Hive.openBox<dynamic>(HiveService.notificationsBox);
      repo = NotificationRepository();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('clearAllNotifications prevents older notifications from being returned', () async {
      final oldNotif = SpendlyNotification(
        id: 'old_1',
        familyId: 'fam_test',
        userId: 'user_test',
        type: NotificationType.expenseAdded,
        title: 'Old Expense',
        body: 'Old body',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await repo.saveLocalNotification(oldNotif);
      expect(repo.getLocalNotifications('fam_test', 'user_test').length, 1);

      // User clears all notifications
      await repo.clearAllNotifications('fam_test', 'user_test');
      expect(repo.getLocalNotifications('fam_test', 'user_test'), isEmpty);

      // Simulating a reopen/re-fetch where old notification attempts to be saved
      final savedOld = await repo.saveLocalNotification(oldNotif);
      expect(savedOld, isFalse);
      expect(repo.getLocalNotifications('fam_test', 'user_test'), isEmpty);

      // A brand new notification created AFTER the clear arrives
      final newNotif = SpendlyNotification(
        id: 'new_1',
        familyId: 'fam_test',
        userId: 'user_test',
        type: NotificationType.budgetWarning,
        title: 'New Budget Alert',
        body: 'New body',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      );

      final savedNew = await repo.saveLocalNotification(newNotif);
      expect(savedNew, isTrue);
      expect(repo.getLocalNotifications('fam_test', 'user_test').length, 1);
      expect(repo.getLocalNotifications('fam_test', 'user_test').first.id, 'new_1');
    });

    test('deleteNotification prevents that notification from returning', () async {
      final notif = SpendlyNotification(
        id: 'del_1',
        familyId: 'fam_test',
        userId: 'user_test',
        type: NotificationType.expenseAdded,
        title: 'Expense to delete',
        body: 'body',
        createdAt: DateTime.now(),
      );

      await repo.saveLocalNotification(notif);
      expect(repo.getLocalNotifications('fam_test', 'user_test').length, 1);

      await repo.deleteNotification('del_1', 'fam_test', 'user_test');
      expect(repo.getLocalNotifications('fam_test', 'user_test'), isEmpty);

      // Cannot be re-saved
      final reSaved = await repo.saveLocalNotification(notif);
      expect(reSaved, isFalse);
      expect(repo.getLocalNotifications('fam_test', 'user_test'), isEmpty);
    });
  });
}
