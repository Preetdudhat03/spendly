import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/core/providers/auth_providers.dart';
import 'package:spendly/core/providers/state_providers.dart' hide AuthState;
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/utils/currency_formatter.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';
import 'package:spendly/features/notifications/services/local_notification_service.dart';
import 'package:spendly/features/notifications/services/push_notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final localService = LocalNotificationService();
  final pushService = PushNotificationService(repo, localService);
  final service = NotificationService(ref, repo, localService, pushService);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

class NotificationService {
  final Ref _ref;
  final NotificationRepository _repo;
  final LocalNotificationService _localService;
  final PushNotificationService _pushService;
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;
  StreamSubscription<AuthState>? _authStateSubscription;
  String? _subscribedFamilyId;
  String? _subscribedUserId;

  NotificationService(this._ref, this._repo, this._localService, this._pushService);

  Future<void> initialize() async {
    await _localService.initialize(
      onNotificationTap: (payload) {
        _handleNotificationPayloadTap(payload);
      },
    );
    await _localService.requestPermission();

    // Initialize Push Notifications (FCM)
    await _pushService.initialize(
      onNotificationOpen: (deepLink) {
        _handleNotificationPayloadTap(deepLink);
      },
    );

    // Listen to Supabase Auth State Changes directly
    _authStateSubscription = _client.auth.onAuthStateChange.listen((data) {
      debugPrint('[NotificationService] Supabase Auth event: ${data.event}');
      if (data.session?.user != null) {
        _pushService.syncDeviceToken();
        _onAuthOrFamilyChanged();
      }
    });

    // Listen to user and family session changes to manage realtime subscriptions & reminders
    _ref.listen(authProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

    _ref.listen(currentUserProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

    _ref.listen(familyProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

    _onAuthOrFamilyChanged();
    debugPrint('[NotificationService] Initialized');
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _cleanupRealtime();
    _pushService.dispose();
  }

  void _onAuthOrFamilyChanged() {
    final user = _ref.read(currentUserProvider);
    final authState = _ref.read(authProvider);
    final family = _ref.read(familyProvider).family;
    final supabaseUser = _client.auth.currentUser;

    final newUserId = supabaseUser?.id ?? user?.id ?? authState.userId ?? (HiveService.settings.get('active_user_id') as String?);
    final newFamilyId = family?.id;

    if (newUserId != null && newUserId.isNotEmpty) {
      _pushService.syncDeviceToken();
    }

    if (newUserId != _subscribedUserId || newFamilyId != _subscribedFamilyId) {
      _cleanupRealtime();

      if (newUserId != null && newUserId.isNotEmpty && newFamilyId != null && newFamilyId.isNotEmpty) {
        _setupRealtime(newFamilyId, newUserId);
        _syncScheduledReminders(newUserId);
      }
    }
  }

  void _setupRealtime(String familyId, String userId) {
    if (_client.auth.currentUser == null) return;

    try {
      _subscribedFamilyId = familyId;
      _subscribedUserId = userId;

      final channelName = 'public:notifications:$familyId';
      _realtimeChannel = _client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              if (payload.eventType == PostgresChangeEvent.insert && payload.newRecord.isNotEmpty) {
                final record = payload.newRecord;
                if (record['family_id'] == familyId) {
                  _handleIncomingRealtimeNotification(record);
                }
              }
            },
          )
          .subscribe((status, [error]) {
            debugPrint('[NotificationService] Realtime channel ($channelName) status: $status, error: $error');
          });

      debugPrint('[NotificationService] Subscribed to realtime notifications for family: $familyId');
    } catch (e) {
      debugPrint('[NotificationService] Realtime subscription failed: $e');
    }
  }

  void _cleanupRealtime() {
    if (_realtimeChannel != null) {
      try {
        _client.removeChannel(_realtimeChannel!);
        debugPrint('[NotificationService] Cleaned up realtime channel for family: $_subscribedFamilyId');
      } catch (e) {
        debugPrint('[NotificationService] Error removing channel: $e');
      }
      _realtimeChannel = null;
    }
    _subscribedFamilyId = null;
    _subscribedUserId = null;
  }

  Future<void> _handleIncomingRealtimeNotification(Map<String, dynamic> record) async {
    try {
      final notification = SpendlyNotification.fromJson(record);
      final currentUserId = _ref.read(authProvider).userId ?? (HiveService.settings.get('active_user_id') as String?);

      // Filter out if user-specific and not for this user
      if (notification.userId != null && notification.userId != currentUserId) {
        return;
      }

      // Save locally (idempotent)
      await _repo.saveLocalNotification(notification);

      // Check user preferences
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final prefs = await _repo.getPreferences(currentUserId);
        if (!_shouldNotifyForPreferences(notification.type, prefs)) {
          return;
        }
      }

      // If notification was created by this user on this device, skip local pop alert to avoid echo
      if (notification.createdBy != null && notification.createdBy == currentUserId) {
        debugPrint('[NotificationService] Ignoring echo notification created by self (${notification.createdBy})');
        return;
      }

      debugPrint('[NotificationService] Showing alert for incoming notification: ${notification.title}');

      // Show local notification pop
      await _localService.showNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        deepLink: notification.deepLink,
        payload: notification.payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error processing realtime record: $e');
    }
  }

  bool _shouldNotifyForPreferences(NotificationType type, NotificationPreferences prefs) {
    if (!prefs.pushEnabled) return false;

    switch (type.category) {
      case NotificationCategory.expense:
        return prefs.expenseAlerts;
      case NotificationCategory.budget:
        return prefs.budgetAlerts;
      case NotificationCategory.family:
        return prefs.familyAlerts;
      case NotificationCategory.reminder:
        return prefs.expenseReminders;
      case NotificationCategory.insight:
        return prefs.spendingInsights;
      case NotificationCategory.system:
        return true;
    }
  }

  void _handleNotificationPayloadTap(String? payloadString) {
    if (payloadString == null || payloadString.isEmpty) return;
    try {
      // Global navigation handler will route through router
      debugPrint('[NotificationService] Deep link tap event received: $payloadString');
    } catch (e) {
      debugPrint('[NotificationService] Deep link parse error: $e');
    }
  }

  // --- Scheduled Expense Reminders ---

  Future<void> _syncScheduledReminders(String userId) async {
    final prefs = await _repo.getPreferences(userId);
    if (!prefs.expenseReminders) {
      await _localService.cancelReminder(1001);
      return;
    }

    final parts = prefs.reminderTime.split(':');
    final hour = int.tryParse(parts.first) ?? 20;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    await _localService.scheduleDailyReminder(
      id: 1001,
      hour: hour,
      minute: minute,
      title: 'Expense Reminder 📝',
      body: "Don't forget to record today's expenses to keep your family budget accurate!",
    );
  }

  // --- Event Generators ---

  /// Emitted when an expense is added
  Future<void> notifyExpenseAdded({
    required String familyId,
    required String expenseId,
    required String memberName,
    required double amount,
    required String category,
    required String createdByUserId,
  }) async {
    final formattedAmount = CurrencyFormatter.format(amount);
    final notificationKey = 'expense_added:$expenseId';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.expenseAdded,
      title: 'New Expense Added 💸',
      body: '$memberName added $formattedAmount for $category.',
      payload: {
        'expense_id': expenseId,
        'amount': amount,
        'category': category,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: createdByUserId,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Emitted when an expense is updated
  Future<void> notifyExpenseUpdated({
    required String familyId,
    required String expenseId,
    required String memberName,
    required double oldAmount,
    required double newAmount,
    required String category,
    required String updatedByUserId,
  }) async {
    final formattedOld = CurrencyFormatter.format(oldAmount);
    final formattedNew = CurrencyFormatter.format(newAmount);
    final notificationKey = 'expense_updated:${expenseId}_${newAmount.toStringAsFixed(2)}';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.expenseUpdated,
      title: 'Expense Updated ✏️',
      body: '$memberName updated $category from $formattedOld to $formattedNew.',
      payload: {
        'expense_id': expenseId,
        'old_amount': oldAmount,
        'new_amount': newAmount,
        'category': category,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: updatedByUserId,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Emitted when an expense is deleted
  Future<void> notifyExpenseDeleted({
    required String familyId,
    required String expenseId,
    required String memberName,
    required double amount,
    required String category,
    required String deletedByUserId,
  }) async {
    final formattedAmount = CurrencyFormatter.format(amount);
    final notificationKey = 'expense_deleted:$expenseId';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.expenseDeleted,
      title: 'Expense Removed 🗑️',
      body: 'An expense of $formattedAmount for $category was deleted.',
      payload: {
        'expense_id': expenseId,
        'amount': amount,
        'category': category,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: deletedByUserId,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Check and emit budget threshold alerts (50%, 80%, 95%, 100%)
  Future<void> checkBudgetThresholds({
    required String familyId,
    required double totalSpent,
    required double budgetLimit,
    required int month,
    required int year,
  }) async {
    if (budgetLimit <= 0) return;

    final ratio = totalSpent / budgetLimit;
    final int percentage = (ratio * 100).toInt();

    // Defined threshold checkpoints
    final thresholds = [80, 95, 100];

    for (final threshold in thresholds) {
      if (percentage >= threshold) {
        final notificationKey = 'budget_alert:$familyId:${year}_$month:$threshold';
        
        NotificationType type;
        String title;
        String body;
        NotificationPriority priority;

        if (threshold >= 100) {
          type = NotificationType.budgetExceeded;
          title = 'Budget Exceeded 🚨';
          body = 'Your monthly family spending (${CurrencyFormatter.format(totalSpent)}) has exceeded the budget of ${CurrencyFormatter.format(budgetLimit)}.';
          priority = NotificationPriority.urgent;
        } else if (threshold >= 95) {
          type = NotificationType.budgetCritical;
          title = 'Critical Budget Alert ⚠️';
          body = "You've used $percentage% of your monthly family budget (${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetLimit)}).";
          priority = NotificationPriority.high;
        } else {
          type = NotificationType.budgetWarning;
          title = 'Budget Alert 💰';
          body = "You've used $percentage% of your monthly family budget.";
          priority = NotificationPriority.normal;
        }

        final notification = SpendlyNotification(
          id: const Uuid().v4(),
          familyId: familyId,
          type: type,
          title: title,
          body: body,
          priority: priority,
          payload: {
            'spent': totalSpent,
            'limit': budgetLimit,
            'percentage': percentage,
            'month': month,
            'year': year,
          },
          deepLink: '/home',
          notificationKey: notificationKey,
          createdAt: DateTime.now(),
        );

        await _repo.createNotification(notification);
      }
    }
  }

  /// Emitted when a new member joins family
  Future<void> notifyFamilyMemberJoined({
    required String familyId,
    required String memberName,
    required String familyName,
    required String joinedUserId,
  }) async {
    final notificationKey = 'family_joined:${familyId}_$joinedUserId';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.familyMemberJoined,
      title: 'New Family Member 👥',
      body: '$memberName joined $familyName.',
      payload: {
        'joined_user_id': joinedUserId,
        'name': memberName,
      },
      deepLink: '/profile',
      notificationKey: notificationKey,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Emitted when a member leaves or is removed
  Future<void> notifyFamilyMemberLeft({
    required String familyId,
    required String memberName,
    required String familyName,
    required String leftUserId,
  }) async {
    final notificationKey = 'family_left:${familyId}_${leftUserId}_${DateTime.now().month}';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.familyMemberLeft,
      title: 'Family Member Left 👤',
      body: '$memberName left $familyName.',
      payload: {
        'left_user_id': leftUserId,
        'name': memberName,
      },
      deepLink: '/profile',
      notificationKey: notificationKey,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }

  /// Emitted for verified analytics insights
  Future<void> notifySpendingInsight({
    required String familyId,
    required String title,
    required String message,
    required String insightKey,
    Map<String, dynamic>? metadata,
  }) async {
    final notificationKey = 'insight:${familyId}_$insightKey';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.spendingInsight,
      title: title,
      body: message,
      payload: metadata ?? {},
      deepLink: '/analytics',
      notificationKey: notificationKey,
      createdAt: DateTime.now(),
    );

    await _repo.createNotification(notification);
  }
}
