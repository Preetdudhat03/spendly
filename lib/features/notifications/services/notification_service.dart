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
  final SupabaseClient? _clientOverride;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  RealtimeChannel? _realtimeChannel;
  StreamSubscription<AuthState>? _authStateSubscription;
  String? _subscribedFamilyId;
  String? _subscribedUserId;
  final Set<String> _recentlyCreatedKeys = <String>{};

  NotificationService(
    this._ref,
    this._repo,
    this._localService,
    this._pushService, {
    SupabaseClient? client,
  }) : _clientOverride = client;

  Future<void> initialize() async {
    // Listen to user and family session changes synchronously so Riverpod listeners
    // are attached within the provider's synchronous build/mount phase
    _ref.listen(authProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

    _ref.listen(currentUserProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

    _ref.listen(familyProvider, (prev, next) {
      _onAuthOrFamilyChanged();
    });

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
    final client = _client;
    if (client != null) {
      _authStateSubscription = client.auth.onAuthStateChange.listen((data) {
        debugPrint('[NOTIFICATION] Supabase Auth event: ${data.event}');
        if (data.event == AuthChangeEvent.signedOut || data.session?.user == null) {
          debugPrint('[NOTIFICATION] Account switch/signout detected via AuthStateChange');
          onSignOut();
        } else if (data.session?.user != null) {
          final userId = data.session!.user.id;
          debugPrint('[NOTIFICATION] Authenticated user signed in: $userId');
          _onUserSignedIn(userId);
        }
      });
    }

    _onAuthOrFamilyChanged();
    debugPrint('[NOTIFICATION] NotificationService Initialized');
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _cleanupRealtime();
    _pushService.dispose();
  }

  Future<void> onSignOut() async {
    debugPrint('[NOTIFICATION] onSignOut initiated');
    try {
      final currentUid = _client?.auth.currentUser?.id ?? _subscribedUserId;
      if (currentUid != null && currentUid.isNotEmpty) {
        await _pushService.unregisterDeviceToken(currentUid);
      }
    } catch (e) {
      debugPrint('[NOTIFICATION] Error unregistering token on signout: $e');
    }

    _cleanupRealtime();

    try {
      await _localService.cancelReminder(1001);
    } catch (e) {
      debugPrint('[NOTIFICATION] Error cancelling reminder: $e');
    }

    _subscribedUserId = null;
    _subscribedFamilyId = null;
    debugPrint('[NOTIFICATION] Previous notification subscriptions disposed');
  }

  Future<void> _onUserSignedIn(String userId) async {
    debugPrint('[NOTIFICATION] Initializing notification services for user: $userId');
    await _pushService.syncDeviceToken();
    _onAuthOrFamilyChanged();
  }

  void _onAuthOrFamilyChanged() {
    final client = _client;
    final supabaseUser = client?.auth.currentUser;
    final user = _ref.read(currentUserProvider);
    final authState = _ref.read(authProvider);
    final family = _ref.read(familyProvider).family;

    // Strict priority: current authenticated Supabase user UID
    final newUserId = supabaseUser?.id ?? user?.id ?? (client == null ? authState.userId : null);
    final newFamilyId = family?.id;

    debugPrint('[NOTIFICATION] Account switch check: newUserId=$newUserId, prevUser=$_subscribedUserId');

    if (newUserId != null && newUserId.isNotEmpty) {
      _pushService.syncDeviceToken();
    }

    if (newUserId == null || newUserId.isEmpty) {
      _cleanupRealtime();
      return;
    }

    if (newUserId != _subscribedUserId || newFamilyId != _subscribedFamilyId) {
      debugPrint('[NOTIFICATION] Switching notification subscription: $_subscribedUserId -> $newUserId');
      _cleanupRealtime();

      if (newFamilyId != null && newFamilyId.isNotEmpty) {
        _setupRealtime(newFamilyId, newUserId);
        _syncScheduledReminders(newUserId);
      }
    }
  }

  Future<String> syncPushToken() async {
    return await _pushService.syncDeviceToken();
  }

  void _setupRealtime(String familyId, String userId) {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;

    try {
      _subscribedFamilyId = familyId;
      _subscribedUserId = userId;

      final channelName = 'public:notifications:$familyId';
      _realtimeChannel = client
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
            debugPrint('[NOTIFICATION] Realtime channel ($channelName) status: $status, error: $error');
          });

      debugPrint('[NOTIFICATION] New notification subscriptions initialized for family: $familyId, user: $userId');
    } catch (e) {
      debugPrint('[NOTIFICATION] Realtime subscription failed: $e');
    }
  }

  void _cleanupRealtime() {
    if (_realtimeChannel != null) {
      try {
        _client?.removeChannel(_realtimeChannel!);
        debugPrint('[NOTIFICATION] Cleaned up realtime channel for family: $_subscribedFamilyId');
      } catch (e) {
        debugPrint('[NOTIFICATION] Error removing channel: $e');
      }
      _realtimeChannel = null;
    }
    _subscribedFamilyId = null;
    _subscribedUserId = null;
  }

  Future<void> _handleIncomingRealtimeNotification(Map<String, dynamic> record) async {
    try {
      final notification = SpendlyNotification.fromJson(record);
      final client = _client;
      final currentUserId = client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id ?? (client == null ? _ref.read(authProvider).userId : null);

      if (currentUserId == null || currentUserId.isEmpty) {
        debugPrint('[NOTIFICATION] Realtime notification ignored: no authenticated user');
        return;
      }

      // Filter out if user-specific and not for this user
      if (notification.userId != null && notification.userId != currentUserId) {
        debugPrint('[NOTIFICATION] Dropping notification targeted to another user (${notification.userId} != $currentUserId)');
        return;
      }

      // Filter out if created before clearedAt or in deletedIds
      final clearedAt = _repo.getClearedAt(notification.familyId, currentUserId);
      if (clearedAt != null && !notification.createdAt.isAfter(clearedAt)) {
        return;
      }
      final deletedIds = _repo.getDeletedIds(notification.familyId, currentUserId);
      if (deletedIds.contains(notification.id)) {
        return;
      }

      // Save locally (idempotent)
      final saved = await _repo.saveLocalNotification(notification);
      if (!saved) return;

      // Check user preferences
      final prefs = await _repo.getPreferences(currentUserId);
      if (!_shouldNotifyForPreferences(notification.type, prefs)) {
        return;
      }

      // 1. If notification was created on this client in this session, skip local pop alert to avoid echo
      final notifKey = notification.notificationKey;
      if (_recentlyCreatedKeys.contains(notification.id) || (notifKey != null && _recentlyCreatedKeys.contains(notifKey))) {
        debugPrint('[NOTIFICATION] Ignoring echo notification created on this client (id=${notification.id}, key=$notifKey)');
        return;
      }

      // 2. If notification was created by this user on this device, skip local pop alert to avoid echo
      if (notification.createdBy != null && notification.createdBy == currentUserId) {
        debugPrint('[NOTIFICATION] Ignoring echo notification created by self (${notification.createdBy})');
        return;
      }

      // 3. Also check if payload contains creator matching current user
      final payloadCreator = notification.payload['created_by'] as String?;
      if (payloadCreator != null && payloadCreator == currentUserId) {
        debugPrint('[NOTIFICATION] Ignoring echo notification created by self via payload ($payloadCreator)');
        return;
      }

      debugPrint('[NOTIFICATION] Showing alert for incoming notification: ${notification.title}');

      // Show local notification pop
      await _localService.showNotification(
        id: notification.id.hashCode,
        tag: notification.id,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        deepLink: notification.deepLink,
        payload: notification.payload,
      );
    } catch (e) {
      debugPrint('[NOTIFICATION] Error processing realtime record: $e');
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

  /// Public entry to resync the local scheduled reminder alarm.
  Future<void> syncScheduledReminders([String? userId]) async {
    final targetId = userId ?? _subscribedUserId ?? _ref.read(authProvider).userId;
    if (targetId == null || targetId.isEmpty) return;
    await _syncScheduledReminders(targetId);
  }

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

  /// Triggers an immediate test reminder notification for verification.
  Future<void> sendTestReminder() async {
    await _localService.showNotification(
      id: 9999,
      title: 'Expense Reminder 📝',
      body: "Don't forget to record today's expenses to keep your family budget accurate!",
      type: NotificationType.expenseReminder,
      deepLink: '/add',
    );
  }

  Future<SpendlyNotification?> _emitNotification(SpendlyNotification notification) async {
    if (notification.id.isNotEmpty) _recentlyCreatedKeys.add(notification.id);
    if (notification.notificationKey != null && notification.notificationKey!.isNotEmpty) {
      _recentlyCreatedKeys.add(notification.notificationKey!);
    }
    return await _repo.createNotification(notification);
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
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
    final effectiveCreator = authUserId ?? createdByUserId;
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
        'created_by': effectiveCreator,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: effectiveCreator,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
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
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
    final effectiveCreator = authUserId ?? updatedByUserId;
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
        'created_by': effectiveCreator,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: effectiveCreator,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
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
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
    final effectiveCreator = authUserId ?? deletedByUserId;
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
        'created_by': effectiveCreator,
      },
      deepLink: '/expenses',
      notificationKey: notificationKey,
      createdBy: effectiveCreator,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
  }

  /// Check and emit budget threshold alerts strictly at 80%, 95%, and 100%
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

    // Strictly 3 alert thresholds: 80%, 95%, and 100%
    const thresholds = [80, 95, 100];

    // 1. For any threshold that spending is currently below, clear the sent flag
    // (e.g. if an expense was deleted or monthly budget was increased)
    for (final threshold in thresholds) {
      if (percentage < threshold) {
        final alertSentKey = 'budget_alert_sent:$familyId:${year}_$month:$threshold';
        await HiveService.settings.delete(alertSentKey);
      }
    }

    // 2. Identify which reached thresholds have not been alerted yet
    final unnotifiedThresholds = <int>[];
    for (final threshold in thresholds) {
      if (percentage >= threshold) {
        final alertSentKey = 'budget_alert_sent:$familyId:${year}_$month:$threshold';
        final notificationKey = 'budget_alert:$familyId:${year}_$month:$threshold';

        final isMarked = HiveService.settings.get(alertSentKey) == true;
        if (isMarked) continue;

        final alreadyInRepo = await _repo.hasNotificationKey(familyId, notificationKey);
        if (alreadyInRepo) {
          await HiveService.settings.put(alertSentKey, true);
          continue;
        }

        unnotifiedThresholds.add(threshold);
      }
    }

    if (unnotifiedThresholds.isEmpty) {
      return; // All reached thresholds have already been alerted!
    }

    // 3. Pick the highest reached unnotified threshold to alert
    // and mark all reached unnotified thresholds as sent so no spam occurs
    final targetThreshold = unnotifiedThresholds.last;
    for (final threshold in unnotifiedThresholds) {
      final alertSentKey = 'budget_alert_sent:$familyId:${year}_$month:$threshold';
      await HiveService.settings.put(alertSentKey, true);
    }

    final notificationKey = 'budget_alert:$familyId:${year}_$month:$targetThreshold';

    final NotificationType type;
    final String title;
    final String body;
    final NotificationPriority priority;

    if (targetThreshold == 100) {
      type = NotificationType.budgetExceeded;
      title = 'Budget Exceeded 🚨';
      body =
          'Your monthly family spending (${CurrencyFormatter.format(totalSpent)}) has reached 100% of the budget (${CurrencyFormatter.format(budgetLimit)}).';
      priority = NotificationPriority.urgent;
    } else if (targetThreshold == 95) {
      type = NotificationType.budgetCritical;
      title = 'Critical Budget Alert ⚠️';
      body =
          "You've used 95% of your monthly family budget (${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetLimit)}).";
      priority = NotificationPriority.high;
    } else {
      type = NotificationType.budgetWarning;
      title = 'Budget Alert 💰';
      body =
          "You've used 80% of your monthly family budget (${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetLimit)}).";
      priority = NotificationPriority.normal;
    }

    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;

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
        'threshold': targetThreshold,
        'month': month,
        'year': year,
      },
      deepLink: '/home',
      notificationKey: notificationKey,
      createdBy: authUserId,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
  }

  /// Emitted when a new member joins family
  Future<void> notifyFamilyMemberJoined({
    required String familyId,
    required String memberName,
    required String familyName,
    required String joinedUserId,
  }) async {
    final notificationKey = 'family_joined:${familyId}_$joinedUserId';
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id ?? joinedUserId;

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
      createdBy: authUserId,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
  }

  /// Emitted when a member leaves or is removed
  Future<void> notifyFamilyMemberLeft({
    required String familyId,
    required String memberName,
    required String familyName,
    required String leftUserId,
  }) async {
    final notificationKey = 'family_left:${familyId}_${leftUserId}_${DateTime.now().month}';
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id ?? leftUserId;

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
      createdBy: authUserId,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
  }

  /// Emitted when an admin requests a member to leave the family
  Future<void> notifyFamilyLeaveRequest({
    required String familyId,
    required String targetUserId,
    required String targetMemberName,
    required String familyName,
    required String requestedByName,
    String? reason,
  }) async {
    final notificationKey =
        'family_leave_request:${familyId}_${targetUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final authUserId =
        _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id ?? '';

    final trimmedReason = reason?.trim();
    final reasonSuffix = (trimmedReason != null && trimmedReason.isNotEmpty)
        ? ' Note: "$trimmedReason"'
        : '';

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      userId: targetUserId,
      familyId: familyId,
      type: NotificationType.familyMemberActivity,
      priority: NotificationPriority.high,
      title: 'Request to Leave Family',
      body:
          '$requestedByName has requested $targetMemberName to leave $familyName.$reasonSuffix',
      payload: {
        'action': 'leave_request',
        'target_user_id': targetUserId,
        'target_member_name': targetMemberName,
        'requested_by': requestedByName,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'reason': trimmedReason,
      },
      deepLink: '/profile',
      notificationKey: notificationKey,
      createdBy: authUserId,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
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
    final authUserId = _client?.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;

    final notification = SpendlyNotification(
      id: const Uuid().v4(),
      familyId: familyId,
      type: NotificationType.spendingInsight,
      title: title,
      body: message,
      payload: metadata ?? {},
      deepLink: '/analytics',
      notificationKey: notificationKey,
      createdBy: authUserId,
      createdAt: DateTime.now(),
    );

    await _emitNotification(notification);
  }
}
