import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/providers/notification_providers.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_empty_state.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_group.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final accentColor = isDark ? const Color(0xFF818CF8) : colorScheme.primary;

    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 64.0;

    final displayedNotifications = state.filteredNotifications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        title: const CapsuleHeader(
          title: 'Notifications',
          icon: Icons.notifications_rounded,
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Push Notifications',
            onPressed: () async {
              SpendlyToast.showInfo(context, 'Syncing push notification token...');
              final result = await notifier.syncPushTokens();
              if (context.mounted) {
                if (result.contains('successfully')) {
                  SpendlyToast.showSuccess(context, result);
                } else {
                  SpendlyToast.showWarning(context, result);
                }
              }
            },
            icon: Icon(
              Icons.cloud_sync_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          if (state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Mark all as read',
                onPressed: () async {
                  await notifier.markAllAsRead();
                  if (context.mounted) {
                    SpendlyToast.showSuccess(context, 'All notifications marked as read');
                  }
                },
                icon: Icon(
                  Icons.done_all_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: contentTopPadding),

          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // All filter chip
                  _buildFilterChip(
                    label: 'All (${state.notifications.length})',
                    isSelected: state.selectedCategory == null && !state.onlyUnread,
                    onTap: () {
                      if (state.onlyUnread) notifier.toggleOnlyUnread();
                      notifier.selectCategory(null);
                    },
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Unread filter chip
                  _buildFilterChip(
                    label: 'Unread (${state.unreadCount})',
                    isSelected: state.onlyUnread,
                    onTap: () => notifier.toggleOnlyUnread(),
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Expense category chip
                  _buildFilterChip(
                    label: 'Expenses',
                    isSelected: state.selectedCategory == NotificationCategory.expense,
                    onTap: () => notifier.selectCategory(NotificationCategory.expense),
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Budget category chip
                  _buildFilterChip(
                    label: 'Budget',
                    isSelected: state.selectedCategory == NotificationCategory.budget,
                    onTap: () => notifier.selectCategory(NotificationCategory.budget),
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Family category chip
                  _buildFilterChip(
                    label: 'Family',
                    isSelected: state.selectedCategory == NotificationCategory.family,
                    onTap: () => notifier.selectCategory(NotificationCategory.family),
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Insights category chip
                  _buildFilterChip(
                    label: 'Insights',
                    isSelected: state.selectedCategory == NotificationCategory.insight,
                    onTap: () => notifier.selectCategory(NotificationCategory.insight),
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Main notification list / empty state
          Expanded(
            child: state.isLoading && state.notifications.isEmpty
                ? _buildShimmerLoading()
                : RefreshIndicator(
                    onRefresh: () async {
                      await notifier.loadNotifications();
                    },
                    child: displayedNotifications.isEmpty
                        ? NotificationEmptyState(
                            isFiltered: state.onlyUnread || state.selectedCategory != null,
                            onResetFilter: () {
                              if (state.onlyUnread) notifier.toggleOnlyUnread();
                              notifier.selectCategory(null);
                            },
                          )
                        : NotificationGroupView(
                            notifications: displayedNotifications,
                            onMarkAsRead: (id) => notifier.markAsRead(id),
                            onDelete: (id) => notifier.deleteNotification(id),
                            onTap: (notification) {
                              if (!notification.isRead) {
                                notifier.markAsRead(notification.id);
                              }
                              if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
                                context.push(notification.deepLink!);
                              }
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? accentColor.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.12))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ShimmerLoading(
      isLoading: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: List.generate(
            4,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerPlaceholder(
                height: 86,
                borderRadius: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
