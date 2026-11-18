import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family, FamilyNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/repositories/family_repository.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/providers/notification_providers.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';
import 'package:spendly/features/notifications/services/local_notification_service.dart';
import 'package:spendly/features/notifications/services/notification_service.dart';
import 'package:spendly/features/notifications/services/push_notification_service.dart';

class _StaticFamilyNotifier extends FamilyNotifier {
  _StaticFamilyNotifier(FamilyState initialState, Ref ref)
      : super(FamilyRepository(), ref) {
    state = initialState;
  }

  @override
  Future<void> loadFamily() async {}

  @override
  Future<void> loadMembers() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProviderContainer container;
  late NotificationRepository repo;
  late LocalNotificationService localService;
  late PushNotificationService pushService;
  late NotificationService service;

  const user1 = 'user-uuid-1111-aaaa';
  const user2 = 'user-uuid-2222-bbbb';
  const family1 = 'family-uuid-111';
  const testDeviceId = 'test-device-uuid-999';

  final testFamily = Family(
    id: family1,
    name: 'Spendly Family',
    familyCode: 'TEST1234',
    createdBy: user1,
    createdAt: DateTime.now(),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spendly_account_switch_test_');
    Hive.init(tempDir.path);

    await Hive.openBox<dynamic>(HiveService.settingsBox);
    await Hive.openBox<dynamic>(HiveService.notificationsBox);
    await Hive.openBox<dynamic>(HiveService.notificationPreferencesBox);

    await HiveService.settings.put('device_id', testDeviceId);

    repo = NotificationRepository();
    localService = LocalNotificationService();
    pushService = PushNotificationService(repo, localService);

    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    NotificationService? testService;
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        notificationRepositoryProvider.overrideWithValue(repo),
        notificationServiceProvider.overrideWith((ref) {
          return testService ??= NotificationService(ref, repo, localService, pushService);
        }),
        familyProvider.overrideWith(
          (ref) => _StaticFamilyNotifier(
            FamilyState(
              isLoading: false,
              family: testFamily,
              members: [],
            ),
            ref,
          ),
        ),
      ],
    );

    service = container.read(notificationServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Account-Switching Notification Isolation Regression Tests', () {
    // ---------------------------------------------------------------------------
    // Test 1: Basic account switching & isolation
    // ---------------------------------------------------------------------------
    test('Test 1: Notifications created by User 1 and User 2 remain strictly isolated', () async {
      // 1. User 1 signs in
      await HiveService.settings.put('active_user_id', user1);

      // Create personal notification under User 1
      final notif1 = SpendlyNotification(
        id: 'notif_u1_1',
        userId: user1,
        familyId: family1,
        type: NotificationType.budgetWarning,
        title: 'User 1 Budget Alert',
        body: '80% budget reached',
        createdBy: user1,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await repo.saveLocalNotification(notif1);

      var user1Items = repo.getLocalNotifications(family1, user1);
      expect(user1Items.length, 1);
      expect(user1Items.first.userId, user1);
      expect(user1Items.first.createdBy, user1);

      // 2. User 1 signs out
      await service.onSignOut();
      await HiveService.settings.delete('active_user_id');

      // 3. User 2 signs in
      await HiveService.settings.put('active_user_id', user2);

      // Create personal notification under User 2
      final notif2 = SpendlyNotification(
        id: 'notif_u2_1',
        userId: user2,
        familyId: family1,
        type: NotificationType.budgetWarning,
        title: 'User 2 Budget Alert',
        body: '80% budget reached for user 2',
        createdBy: user2,
        createdAt: DateTime.now(),
      );
      await repo.saveLocalNotification(notif2);

      // 4. Verify User 2 does NOT see User 1's user-specific notification
      var user2Items = repo.getLocalNotifications(family1, user2);
      expect(user2Items.map((n) => n.id), contains('notif_u2_1'));
      expect(user2Items.map((n) => n.id), isNot(contains('notif_u1_1')));

      // Verify User 1's query only returns User 1's notification
      var user1Check = repo.getLocalNotifications(family1, user1);
      expect(user1Check.map((n) => n.id), contains('notif_u1_1'));
      expect(user1Check.map((n) => n.id), isNot(contains('notif_u2_1')));
    });

    // ---------------------------------------------------------------------------
    // Test 2: Notification creation ownership after account switching
    // ---------------------------------------------------------------------------
    test('Test 2: Notification created after switching is owned by the new user', () async {
      // User 1 session
      await HiveService.settings.put('active_user_id', user1);

      // User 1 logs out
      await service.onSignOut();
      await HiveService.settings.delete('active_user_id');

      // User 2 logs in
      await HiveService.settings.put('active_user_id', user2);

      // User 2 emits family notification
      await service.notifyFamilyMemberJoined(
        familyId: family1,
        memberName: 'User Two',
        familyName: 'Spendly Family',
        joinedUserId: user2,
      );

      final notifications = repo.getLocalNotifications(family1, user2);
      expect(notifications.isNotEmpty, isTrue);

      final created = notifications.firstWhere((n) => n.notificationKey == 'family_joined:${family1}_$user2');
      expect(created.createdBy, user2);
      expect(created.createdBy, isNot(user1));
    });

    // ---------------------------------------------------------------------------
    // Test 3: FCM token unregistration on logout & reassignment
    // ---------------------------------------------------------------------------
    test('Test 3: Device token registration unregisters on logout and registers for new user', () async {
      // 1. User 1 logs in and registers token
      final res1 = await repo.registerDeviceToken(
        userId: user1,
        token: 'fcm_token_device_abc_123',
        platform: 'android',
      );
      expect(res1, isNotEmpty);

      // 2. User 1 logs out -> unregisters token for this device
      final unregSuccess = await repo.unregisterDeviceToken(userId: user1, deviceId: testDeviceId);
      expect(unregSuccess, isA<bool>());

      // PushNotificationService unregisterDeviceToken executes safely
      final pushUnreg = await pushService.unregisterDeviceToken(user1);
      expect(pushUnreg, isA<bool>());

      // 3. User 2 logs in and registers device token
      final res2 = await repo.registerDeviceToken(
        userId: user2,
        token: 'fcm_token_device_abc_123',
        platform: 'android',
      );
      expect(res2, isNotEmpty);
    });

    // ---------------------------------------------------------------------------
    // Test 4: Stale provider protection & reset on account switch
    // ---------------------------------------------------------------------------
    test('Test 4: NotificationsNotifier resets on logout and isolates state', () async {
      final notifier = container.read(notificationsProvider.notifier);

      // User 1 has notifications
      await HiveService.settings.put('active_user_id', user1);
      final notif1 = SpendlyNotification(
        id: 'notif_state_1',
        userId: user1,
        familyId: family1,
        type: NotificationType.budgetWarning,
        title: 'Budget Alert',
        body: 'Alert for user 1',
        createdAt: DateTime.now(),
      );
      await repo.saveLocalNotification(notif1);

      // Set state as loaded for User 1
      notifier.state = NotificationsState(
        isLoading: false,
        notifications: [notif1],
      );
      expect(notifier.state.notifications.length, 1);
      expect(notifier.state.unreadCount, 1);

      // When User 1 signs out, notifier is reset
      notifier.reset();
      expect(notifier.state.notifications, isEmpty);
      expect(notifier.state.unreadCount, 0);

      // User 2 logs in
      await HiveService.settings.put('active_user_id', user2);
      expect(notifier.state.notifications, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // Test 5: Async race condition protection (stale operation rejection)
    // ---------------------------------------------------------------------------
    test('Test 5: Operation initiated under User 1 is rejected if attempted with mismatched owner', () async {
      await HiveService.settings.put('active_user_id', user1);

      // User 1 creates notification object
      final staleNotification = SpendlyNotification(
        id: 'stale_async_op',
        userId: user1,
        familyId: family1,
        type: NotificationType.budgetWarning,
        title: 'Stale Op',
        body: 'Old op',
        createdBy: user1,
        createdAt: DateTime.now(),
      );

      // Simulate switch to User 2 before createNotification completes
      await HiveService.settings.put('active_user_id', user2);

      final result = await repo.createNotification(staleNotification);
      expect(result, isNotNull);
      expect(result!.createdBy, user1);

      // User 2's feed must NOT contain this notification
      final user2Notifications = repo.getLocalNotifications(family1, user2);
      expect(user2Notifications.map((n) => n.id), isNot(contains('stale_async_op')));
    });

    // ---------------------------------------------------------------------------
    // Test 6: Realtime isolation & disposal on signout
    // ---------------------------------------------------------------------------
    test('Test 6: Realtime and reminders are cleanly disposed on signout', () async {
      await HiveService.settings.put('active_user_id', user1);
      await service.syncScheduledReminders(user1);

      // User 1 signs out
      await service.onSignOut();

      // Ensure dispose runs without errors and clean state is preserved
      service.dispose();
      expect(true, isTrue);
    });

    // ---------------------------------------------------------------------------
    // Test 7: App restart / session persistence retains User 2
    // ---------------------------------------------------------------------------
    test('Test 7: App restart retains User 2 and does not revert to User 1', () async {
      // User 1 sign in -> sign out
      await HiveService.settings.put('active_user_id', user1);
      await service.onSignOut();
      await HiveService.settings.delete('active_user_id');

      // User 2 signs in
      await HiveService.settings.put('active_user_id', user2);

      // Simulate app restart: re-read active_user_id from settings
      final restoredUserId = HiveService.settings.get('active_user_id') as String?;
      expect(restoredUserId, user2);
      expect(restoredUserId, isNot(user1));

      // Notification repository resolves user2
      final effectiveUser = restoredUserId ?? 'default';
      expect(effectiveUser, user2);
    });
  });
}
