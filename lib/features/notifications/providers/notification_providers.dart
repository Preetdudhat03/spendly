import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';
import 'package:spendly/features/notifications/services/notification_service.dart';

class NotificationsState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<SpendlyNotification> notifications;
  final NotificationCategory? selectedCategory;
  final bool onlyUnread;
  final String? error;

  const NotificationsState({
    required this.isLoading,
    this.isLoadingMore = false,
    required this.notifications,
    this.selectedCategory,
    this.onlyUnread = false,
    this.error,
  });

  factory NotificationsState.initial() => const NotificationsState(
        isLoading: false,
        notifications: [],
      );

  NotificationsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<SpendlyNotification>? notifications,
    NotificationCategory? selectedCategory,
    bool clearCategory = false,
    bool? onlyUnread,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notifications: notifications ?? this.notifications,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      onlyUnread: onlyUnread ?? this.onlyUnread,
      error: error,
    );
  }

  List<SpendlyNotification> get filteredNotifications {
    var list = notifications;
    if (onlyUnread) {
      list = list.where((n) => !n.isRead).toList();
    }
    if (selectedCategory != null) {
      list = list.where((n) => n.type.category == selectedCategory).toList();
    }
    return list;
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationsState &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        listEquals(other.notifications, notifications) &&
        other.selectedCategory == selectedCategory &&
        other.onlyUnread == onlyUnread &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        isLoadingMore,
        Object.hashAll(notifications),
        selectedCategory,
        onlyUnread,
        error,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository _repo;
  final Ref _ref;
  StreamSubscription? _hiveSubscription;
  Timer? _debounceTimer;

  NotificationsNotifier(this._repo, this._ref) : super(NotificationsState.initial()) {
    // Keep notification service active
    _ref.read(notificationServiceProvider);

    _listenToHive();
    loadNotifications();

    // Listen to family changes to reload family-specific notifications
    _ref.listen(familyProvider, (previous, next) {
      if (previous?.family?.id != next.family?.id) {
        loadNotifications();
      }
    });
  }

  void _listenToHive() {
    _hiveSubscription?.cancel();
    try {
      _hiveSubscription = HiveService.notifications.watch().listen((_) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          _reloadFromLocalCache();
        });
      });
    } catch (e) {
      debugPrint('[NotificationsNotifier] Hive watch listener warning: $e');
    }
  }

  @override
  void dispose() {
    _hiveSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    final family = _ref.read(familyProvider).family;
    final user = _ref.read(authProvider).userId;

    if (family == null) {
      state = NotificationsState.initial();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    // 1. Immediately populate from local cache
    final localItems = _repo.getLocalNotifications(family.id, user);
    state = state.copyWith(
      isLoading: false,
      notifications: localItems,
    );

    // 2. Fetch latest from Supabase in background
    try {
      final remoteItems = await _repo.fetchRemoteNotifications(
        familyId: family.id,
        userId: user,
      );
      state = state.copyWith(
        isLoading: false,
        notifications: remoteItems,
      );
    } catch (e) {
      debugPrint('[NotificationsNotifier] Background fetch notice: $e');
    }
  }

  void _reloadFromLocalCache() {
    final family = _ref.read(familyProvider).family;
    final user = _ref.read(authProvider).userId;
    if (family == null) return;

    final localItems = _repo.getLocalNotifications(family.id, user);
    state = state.copyWith(notifications: localItems);
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    _reloadFromLocalCache();
  }

  Future<void> markAllAsRead() async {
    final family = _ref.read(familyProvider).family;
    final user = _ref.read(authProvider).userId;
    if (family == null) return;

    await _repo.markAllAsRead(family.id, user);
    _reloadFromLocalCache();
  }

  Future<void> deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    _reloadFromLocalCache();
  }

  void selectCategory(NotificationCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void toggleOnlyUnread() {
    state = state.copyWith(onlyUnread: !state.onlyUnread);
  }

  Future<String> syncPushTokens() async {
    return await _ref.read(notificationServiceProvider).syncPushToken();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repo, ref);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.unreadCount;
});

// --- Notification Preferences Provider ---

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationPreferencesNotifier(this._repo, this._ref)
      : super(const NotificationPreferences()) {
    _loadPreferences();
    _ref.listen(authProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        _loadPreferences();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final userId = _ref.read(authProvider).userId;
    if (userId != null && userId.isNotEmpty) {
      final prefs = await _repo.getPreferences(userId);
      state = prefs;
    }
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    state = newPrefs;
    final userId = _ref.read(authProvider).userId;
    if (userId != null && userId.isNotEmpty) {
      await _repo.updatePreferences(userId, newPrefs);
    }
  }

  Future<void> togglePushEnabled(bool value) async {
    await updatePreferences(state.copyWith(pushEnabled: value));
  }

  Future<void> toggleExpenseAlerts(bool value) async {
    await updatePreferences(state.copyWith(expenseAlerts: value));
  }

  Future<void> toggleBudgetAlerts(bool value) async {
    await updatePreferences(state.copyWith(budgetAlerts: value));
  }

  Future<void> toggleFamilyAlerts(bool value) async {
    await updatePreferences(state.copyWith(familyAlerts: value));
  }

  Future<void> toggleSpendingInsights(bool value) async {
    await updatePreferences(state.copyWith(spendingInsights: value));
  }

  Future<void> toggleExpenseReminders(bool value) async {
    await updatePreferences(state.copyWith(expenseReminders: value));
  }

  Future<void> setReminderTime(String timeStr) async {
    await updatePreferences(state.copyWith(reminderTime: timeStr));
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationPreferencesNotifier(repo, ref);
});
