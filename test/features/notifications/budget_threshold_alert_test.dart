import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';
import 'package:spendly/features/notifications/services/local_notification_service.dart';
import 'package:spendly/features/notifications/services/notification_service.dart';
import 'package:spendly/features/notifications/services/push_notification_service.dart';

final _testRefProvider = Provider<Ref>((ref) => ref);

void main() {
  late Directory tempDir;
  late ProviderContainer container;
  late NotificationRepository repo;
  late NotificationService service;

  const familyId = 'family_test_123';
  const month = 10;
  const year = 2026;
  const budgetLimit = 10000.0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spendly_budget_test_');
    Hive.init(tempDir.path);

    await Hive.openBox<dynamic>(HiveService.settingsBox);
    await Hive.openBox<dynamic>(HiveService.notificationsBox);

    container = ProviderContainer();
    final ref = container.read(_testRefProvider);

    repo = NotificationRepository();
    final localService = LocalNotificationService();
    final pushService = PushNotificationService(repo, localService);

    service = NotificationService(ref, repo, localService, pushService);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Strict 3-Threshold Budget Alert Tests (80%, 95%, 100%)', () {
    test('Spending below 80% (79%) does not trigger any notification', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 7900.0, // 79%
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications, isEmpty);

      final is80Marked = HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:80');
      expect(is80Marked, isNull);
    });

    test('Spending at 80% triggers exactly one warning alert', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0, // exactly 80%
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications.length, 1);

      final alert = notifications.first;
      expect(alert.type, NotificationType.budgetWarning);
      expect(alert.notificationKey, 'budget_alert:$familyId:${year}_$month:80');
      expect(alert.body, contains('80%'));
      expect(alert.priority, NotificationPriority.normal);

      final is80Marked = HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:80');
      expect(is80Marked, isTrue);
    });

    test('Intermediate spending from 81% through 94% does NOT trigger additional alerts', () async {
      // 1. Initial 80% alert
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      expect(repo.getLocalNotifications(familyId).length, 1);

      // 2. Spending increases incrementally: 81%, 82%, 85%, 90%, 94%
      final intermediateAmounts = [8100.0, 8200.0, 8500.0, 9000.0, 9400.0, 9499.0];
      for (final amount in intermediateAmounts) {
        await service.checkBudgetThresholds(
          familyId: familyId,
          totalSpent: amount,
          budgetLimit: budgetLimit,
          month: month,
          year: year,
        );
      }

      // Total count must STILL be exactly 1
      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications.length, 1);
    });

    test('Spending at 95% triggers the second alert (critical)', () async {
      // 80% first
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      // Reaching 95%
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 9500.0, // 95%
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications.length, 2);

      final alert95 = notifications.firstWhere((n) => n.notificationKey == 'budget_alert:$familyId:${year}_$month:95');
      expect(alert95.type, NotificationType.budgetCritical);
      expect(alert95.body, contains('95%'));
      expect(alert95.priority, NotificationPriority.high);

      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:95'), isTrue);
    });

    test('Intermediate spending from 96% through 99% does NOT trigger additional alerts', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 9500.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      expect(repo.getLocalNotifications(familyId).length, 2);

      for (final spent in [9600.0, 9750.0, 9900.0, 9990.0]) {
        await service.checkBudgetThresholds(
          familyId: familyId,
          totalSpent: spent,
          budgetLimit: budgetLimit,
          month: month,
          year: year,
        );
      }

      expect(repo.getLocalNotifications(familyId).length, 2);
    });

    test('Spending at 100% or above triggers the third alert (exceeded)', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 9500.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 10000.0, // 100%
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications.length, 3);

      final alert100 = notifications.firstWhere((n) => n.notificationKey == 'budget_alert:$familyId:${year}_$month:100');
      expect(alert100.type, NotificationType.budgetExceeded);
      expect(alert100.body, contains('100%'));
      expect(alert100.priority, NotificationPriority.urgent);

      // Additional expenses beyond 100% (e.g. 105%, 120%) should not trigger any more
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 10500.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 12000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      expect(repo.getLocalNotifications(familyId).length, 3);
    });

    test('Direct jump to 100% sends only the 100% alert and marks lower milestones as satisfied', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 10500.0, // 105% directly
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );

      final notifications = repo.getLocalNotifications(familyId);
      expect(notifications.length, 1);
      expect(notifications.first.type, NotificationType.budgetExceeded);

      // Lower thresholds must be marked as sent so they do not fire on subsequent calls
      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:80'), isTrue);
      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:95'), isTrue);
      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:100'), isTrue);

      // Subsequent call at 106% produces zero additional alerts
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 10600.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      expect(repo.getLocalNotifications(familyId).length, 1);
    });

    test('Deleting an expense or increasing budget resets threshold flag for re-alerting if reached again', () async {
      // 1. Spend reaches 80%
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:80'), isTrue);

      // 2. Budget is increased from 10,000 to 20,000 (spending is now 8,000 / 20,000 = 40%)
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: 20000.0,
        month: month,
        year: year,
      );

      // The sent flag for 80% must be reset (cleared)
      expect(HiveService.settings.get('budget_alert_sent:$familyId:${year}_$month:80'), isNull);
    });

    test('clearAllNotifications deletes all notifications from phone storage', () async {
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 8000.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      await service.checkBudgetThresholds(
        familyId: familyId,
        totalSpent: 9500.0,
        budgetLimit: budgetLimit,
        month: month,
        year: year,
      );
      expect(repo.getLocalNotifications(familyId).length, 2);

      // Right tick action: delete all notifications from phone
      await repo.clearAllNotifications(familyId);

      final remaining = repo.getLocalNotifications(familyId);
      expect(remaining, isEmpty);
    });
  });
}
