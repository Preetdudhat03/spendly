import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

class SpendlyCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? headerAction;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SpendlyCard({
    super.key,
    required this.child,
    this.title,
    this.headerAction,
    this.actions,
    this.padding,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final borderCol = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    final bg = backgroundColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white);

    final cardContent = Padding(
      padding: padding ?? EdgeInsets.all(spendly.spacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || headerAction != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : spendly.colors.neutral900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                if (headerAction != null) headerAction!,
              ],
            ),
            SizedBox(height: spendly.spacing.x4),
          ],
          child,
          if (actions != null && actions!.isNotEmpty) ...[
            SizedBox(height: spendly.spacing.x4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: spendly.radius.large,
          border: Border.all(color: borderCol, width: 1.2),
          boxShadow: spendly.elevation.surface1,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }
}

class SpendlyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const SpendlyStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return SpendlyCard(
      onTap: onTap,
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
                  letterSpacing: -0.1,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? spendly.colors.neutral400,
                ),
            ],
          ),
          SizedBox(height: spendly.spacing.x2),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ??
                  (theme.brightness == Brightness.dark
                      ? Colors.white
                      : spendly.colors.neutral900),
              letterSpacing: -0.8,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: spendly.spacing.x1),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: spendly.colors.neutral400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SpendlySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color badgeBg;
  final Color badgeFg;
  final IconData? icon;
  final VoidCallback? onTap;

  const SpendlySummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.badgeBg,
    required this.badgeFg,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return SpendlyCard(
      onTap: onTap,
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(spendly.spacing.x2),
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeFg, size: 20),
            ),
            SizedBox(width: spendly.spacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: spendly.colors.neutral500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpendlyChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;
  final Widget? headerAction;

  const SpendlyChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return SpendlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: spendly.spacing.x1),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: spendly.colors.neutral400,
                      ),
                    ),
                  ],
                ],
              ),
              if (headerAction != null) headerAction!,
            ],
          ),
          SizedBox(height: spendly.spacing.x5),
          SizedBox(
            height: 220,
            child: chart,
          ),
        ],
      ),
    );
  }
}

class SpendlyExpenseCard extends StatelessWidget {
  final String title;
  final String category;
  final String amount;
  final String date;
  final String? member;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SpendlyExpenseCard({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.member,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final catColor = spendly.charts.getCategoryColor(category);

    return Container(
      margin: EdgeInsets.only(bottom: spendly.spacing.x2),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: spendly.radius.medium,
        border: Border.all(
          color: theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: EdgeInsets.symmetric(horizontal: spendly.spacing.x4, vertical: spendly.spacing.x1),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              category.isNotEmpty ? category.substring(0, 1).toUpperCase() : 'E',
              style: TextStyle(
                color: catColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
          ),
        ),
        subtitle: Text(
          '${member != null ? "$member • " : ""}$date',
          style: theme.textTheme.bodySmall?.copyWith(
            color: spendly.colors.neutral400,
          ),
        ),
        trailing: Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
          ),
        ),
      ),
    );
  }
}

class SpendlyLoadingCard extends StatelessWidget {
  final double height;

  const SpendlyLoadingCard({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: spendly.radius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class SpendlyMemberCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String initials;
  final Widget? trailing;

  const SpendlyMemberCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return SpendlyCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: spendly.colors.primary.withOpacity(0.12),
            child: Text(
              initials,
              style: TextStyle(
                color: spendly.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: spendly.spacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(color: spendly.colors.neutral400),
                ),
                SizedBox(height: spendly.spacing.x1),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x2, vertical: 2),
                  decoration: BoxDecoration(
                    color: spendly.colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: spendly.colors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SpendlyMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? percentage;
  final bool isPositive;

  const SpendlyMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.percentage,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: spendly.colors.neutral400,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: spendly.spacing.x1),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
              ),
            ),
            if (percentage != null) ...[
              SizedBox(width: spendly.spacing.x1),
              Text(
                percentage!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? spendly.colors.success : spendly.colors.error,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
