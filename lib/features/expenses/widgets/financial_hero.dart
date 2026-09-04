import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialHero extends StatelessWidget {
  final double monthTotal;
  final NumberFormat currencyFormat;
  final double? previousMonthTotal;

  const FinancialHero({
    super.key,
    required this.monthTotal,
    required this.currencyFormat,
    this.previousMonthTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Calculate percentage change compared to previous month if available
    String? trendText;
    bool isTrendUp = false;
    if (previousMonthTotal != null && previousMonthTotal! > 0) {
      final diffPercent = ((monthTotal - previousMonthTotal!) / previousMonthTotal!) * 100;
      isTrendUp = diffPercent > 0;
      final sign = isTrendUp ? '↑' : '↓';
      trendText = '$sign ${diffPercent.abs().toStringAsFixed(1)}% vs last month';
    }

    final formattedAmount = currencyFormat.format(monthTotal);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.6)
            : colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withOpacity(0.3)
              : colorScheme.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sub-label with tracked uppercase typography
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL SPENT THIS MONTH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dominant Hero Amount Display
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              formattedAmount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -1.8,
                height: 1.05,
              ),
            ),
          ),

          // Optional Trend / Contextual Pill
          if (trendText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isTrendUp
                    ? colorScheme.error.withOpacity(0.12)
                    : colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                trendText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isTrendUp ? colorScheme.error : colorScheme.secondary,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
