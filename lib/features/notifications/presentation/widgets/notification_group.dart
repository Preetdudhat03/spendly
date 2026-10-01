import 'package:flutter/material.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/presentation/widgets/notification_tile.dart';

class NotificationGroupView extends StatelessWidget {
  final List<SpendlyNotification> notifications;
  final Function(String id)? onMarkAsRead;
  final Function(String id)? onDelete;
  final Function(SpendlyNotification notification)? onTap;

  const NotificationGroupView({
    super.key,
    required this.notifications,
    this.onMarkAsRead,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <SpendlyNotification>[];
    final yesterdayList = <SpendlyNotification>[];
    final earlierList = <SpendlyNotification>[];

    for (final n in notifications) {
      final nDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (nDate.isAtSameMomentAs(today)) {
        todayList.add(n);
      } else if (nDate.isAtSameMomentAs(yesterday)) {
        yesterdayList.add(n);
      } else {
        earlierList.add(n);
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        if (todayList.isNotEmpty) ...[
          _buildSectionHeader('Today', todayList.length, colorScheme),
          const SizedBox(height: 8),
          ...todayList.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NotificationTile(
                  notification: n,
                  onMarkAsRead: () => onMarkAsRead?.call(n.id),
                  onDismissed: () => onDelete?.call(n.id),
                  onTap: () => onTap?.call(n),
                ),
              )),
          const SizedBox(height: 14),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildSectionHeader('Yesterday', yesterdayList.length, colorScheme),
          const SizedBox(height: 8),
          ...yesterdayList.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NotificationTile(
                  notification: n,
                  onMarkAsRead: () => onMarkAsRead?.call(n.id),
                  onDismissed: () => onDelete?.call(n.id),
                  onTap: () => onTap?.call(n),
                ),
              )),
          const SizedBox(height: 14),
        ],
        if (earlierList.isNotEmpty) ...[
          _buildSectionHeader('Earlier', earlierList.length, colorScheme),
          const SizedBox(height: 8),
          ...earlierList.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NotificationTile(
                  notification: n,
                  onMarkAsRead: () => onMarkAsRead?.call(n.id),
                  onDismissed: () => onDelete?.call(n.id),
                  onTap: () => onTap?.call(n),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
