import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SpendingMetricCards extends StatelessWidget {
  final String todayAmount;
  final String remainingAmount;
  final bool hasBudget;
  final bool isBudgetExceeded;
  final String budgetLimitFormatted;

  const SpendingMetricCards({
    super.key,
    required this.todayAmount,
    required this.remainingAmount,
    required this.hasBudget,
    required this.isBudgetExceeded,
    required this.budgetLimitFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TODAY'S SPENDING CARD
          Expanded(
            child: _buildMetricTile(
              context,
              label: 'TODAY',
              amount: todayAmount,
              amountColor: colorScheme.onSurface,
              subtitle: "Today's spending",
              subtitleColor: colorScheme.onSurfaceVariant,
              icon: LucideIcons.calendar,
              accentColor: colorScheme.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 14),

          // 2. REMAINING BUDGET CARD
          Expanded(
            child: _buildMetricTile(
              context,
              label: 'REMAINING',
              amount: remainingAmount,
              amountColor: isBudgetExceeded ? colorScheme.error : colorScheme.onSurface,
              subtitle: !hasBudget
                  ? 'Budget not set'
                  : (isBudgetExceeded
                      ? 'Budget exceeded'
                      : 'of $budgetLimitFormatted budget'),
              subtitleColor: isBudgetExceeded ? colorScheme.error : colorScheme.onSurfaceVariant,
              icon: LucideIcons.wallet,
              accentColor: isBudgetExceeded ? colorScheme.error : const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String amount,
    required Color amountColor,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Tag + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: amountColor,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle context
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
