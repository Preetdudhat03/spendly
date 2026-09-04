import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double familySpent;
  final double budgetLimit;
  final double budgetPercent;
  final Color budgetColor;
  final NumberFormat currencyFormat;

  const BudgetOverviewCard({
    super.key,
    required this.familySpent,
    required this.budgetLimit,
    required this.budgetPercent,
    required this.budgetColor,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cleanPercent = budgetPercent.clamp(0.0, 1.0);
    final remainingBudget = (budgetLimit - familySpent) > 0 ? (budgetLimit - familySpent) : 0.0;
    final isExceeded = familySpent > budgetLimit && budgetLimit > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withOpacity(0.4)
              : colorScheme.outline.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Progress Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currencyFormat.format(familySpent)} spent of ${currencyFormat.format(budgetLimit)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: budgetColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: budgetColor.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(budgetPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: budgetColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar with smooth rounded ends
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.outline.withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: cleanPercent,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: budgetColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: budgetColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Metric Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(familySpent),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isExceeded ? 'EXCEEDED BY' : 'REMAINING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isExceeded ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExceeded
                        ? currencyFormat.format(familySpent - budgetLimit)
                        : currencyFormat.format(remainingBudget),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExceeded ? colorScheme.error : budgetColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
