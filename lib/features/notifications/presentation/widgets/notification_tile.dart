import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final SpendlyNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final VoidCallback? onMarkAsRead;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismissed,
    this.onMarkAsRead,
  });

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && dateTime.day == now.subtract(const Duration(days: 1)).day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  IconData _getCategoryIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAdded:
        return Icons.shopping_bag_rounded;
      case NotificationType.expenseUpdated:
        return Icons.edit_note_rounded;
      case NotificationType.expenseDeleted:
        return Icons.delete_outline_rounded;
      case NotificationType.familyMemberJoined:
        return Icons.group_add_rounded;
      case NotificationType.familyMemberLeft:
        return Icons.person_remove_rounded;
      case NotificationType.familyMemberActivity:
        return Icons.groups_rounded;
      case NotificationType.budgetWarning:
        return Icons.warning_amber_rounded;
      case NotificationType.budgetCritical:
      case NotificationType.budgetExceeded:
        return Icons.error_outline_rounded;
      case NotificationType.budgetReset:
        return Icons.restart_alt_rounded;
      case NotificationType.expenseReminder:
      case NotificationType.recurringExpenseReminder:
        return Icons.alarm_rounded;
      case NotificationType.spendingInsight:
      case NotificationType.unusualSpending:
        return Icons.insights_rounded;
      case NotificationType.syncCompleted:
        return Icons.sync_rounded;
      case NotificationType.syncFailed:
        return Icons.sync_problem_rounded;
      case NotificationType.securityAlert:
        return Icons.security_rounded;
    }
  }

  Color _getIconColor(NotificationType type, bool isDark) {
    switch (type.category) {
      case NotificationCategory.expense:
        return isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
      case NotificationCategory.budget:
        if (type == NotificationType.budgetExceeded || type == NotificationType.budgetCritical) {
          return const Color(0xFFEF4444);
        }
        return const Color(0xFFF59E0B);
      case NotificationCategory.family:
        return const Color(0xFF0EA5E9);
      case NotificationCategory.reminder:
        return const Color(0xFF8B5CF6);
      case NotificationCategory.insight:
        return const Color(0xFF10B981);
      case NotificationCategory.system:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final iconColor = _getIconColor(notification.type, isDark);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: Semantics(
        button: true,
        label: '${notification.title}, ${notification.body}, ${_formatRelativeTime(notification.createdAt)}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onMarkAsRead?.call();
              if (onTap != null) {
                onTap!();
              } else if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
                context.push(notification.deepLink!);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white)
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : colorScheme.primaryContainer.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: !notification.isRead
                      ? (isDark
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.5)
                          : const Color(0xFF818CF8).withValues(alpha: 0.4))
                      : (isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.6)
                          : const Color(0xFFE2E8F0)),
                  width: !notification.isRead ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(notification.type),
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRelativeTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!notification.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                            color: notification.isRead
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
