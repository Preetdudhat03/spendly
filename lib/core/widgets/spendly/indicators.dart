import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';
import 'cards.dart';

class SpendlyProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const SpendlyProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBg = backgroundColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final baseColor = color ?? spendly.colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: baseBg,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

class SpendlyBudgetIndicator extends StatelessWidget {
  final double percent; // e.g., 0.85 for 85%
  final String label;
  final String trailing;

  const SpendlyBudgetIndicator({
    super.key,
    required this.percent,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    Color color = spendly.colors.success;
    if (percent > 0.7 && percent <= 0.9) {
      color = spendly.colors.warning;
    } else if (percent > 0.9) {
      color = spendly.colors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              trailing,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: spendly.spacing.x2),
        SpendlyProgressBar(
          value: percent,
          color: color,
          height: 10,
        ),
      ],
    );
  }
}

class SpendlyHealthIndicator extends StatelessWidget {
  final double score; // 0.0 to 100.0
  final String title;
  final String description;

  const SpendlyHealthIndicator({
    super.key,
    required this.score,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    Color healthColor = spendly.colors.success;
    if (score < 50) {
      healthColor = spendly.colors.error;
    } else if (score < 80) {
      healthColor = spendly.colors.warning;
    }

    return SpendlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: spendly.colors.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x2, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${score.toInt()}/100',
                  style: TextStyle(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spendly.spacing.x3),
          SpendlyProgressBar(
            value: score / 100.0,
            color: healthColor,
            height: 10,
          ),
          SizedBox(height: spendly.spacing.x3),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: spendly.colors.neutral400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
