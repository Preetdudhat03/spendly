import 'package:flutter/material.dart';

class NotificationEmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onResetFilter;

  const NotificationEmptyState({
    super.key,
    this.isFiltered = false,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final accentColor = isDark ? const Color(0xFF818CF8) : colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.3 : 0.18),
                  width: 2,
                ),
              ),
              child: Icon(
                isFiltered ? Icons.filter_alt_off_rounded : Icons.notifications_none_rounded,
                size: 38,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No Matching Notifications' : "You're all caught up! 🎉",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'No notifications match the selected filter criteria. Try resetting your filter.'
                  : 'New family expense updates, budget alerts, and spending insights will show up here.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered && onResetFilter != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Show All Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
