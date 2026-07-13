import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

class SpendlySectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SpendlySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spendly.spacing.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : spendly.colors.neutral900,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: spendly.colors.neutral400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SpendlyFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const SpendlyFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    final bg = isSelected
        ? spendly.colors.primary.withOpacity(0.12)
        : (theme.brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white);

    final fg = isSelected
        ? spendly.colors.primary
        : spendly.colors.neutral500;

    final borderCol = isSelected
        ? spendly.colors.primary
        : (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE5E7EB));

    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: spendly.animation.fast,
        padding: EdgeInsets.symmetric(
          horizontal: spendly.spacing.x3,
          vertical: spendly.spacing.x2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class SpendlySegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;

  const SpendlySegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);
    final activeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final activeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onValueChanged(index),
              child: AnimatedContainer(
                duration: spendly.animation.fast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: activeBorder) : null,
                  boxShadow: isSelected ? spendly.elevation.surface1 : null,
                ),
                child: Center(
                  child: Text(
                    segments[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : spendly.colors.neutral900)
                          : spendly.colors.neutral500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SpendlyAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const SpendlyAvatar({
    super.key,
    required this.initials,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? spendly.colors.primary.withOpacity(0.12),
      child: Text(
        initials,
        style: TextStyle(
          color: textColor ?? spendly.colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

class SpendlySkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SpendlySkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SpendlySkeleton> createState() => _SpendlySkeletonState();
}

class _SpendlySkeletonState extends State<SpendlySkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SpendlyEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;

  const SpendlyEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spendly.spacing.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: spendly.colors.neutral300),
            SizedBox(height: spendly.spacing.x4),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spendly.spacing.x2),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(color: spendly.colors.neutral400),
              textAlign: TextAlign.center,
            ),
            if (primaryActionLabel != null && onPrimaryAction != null) ...[
              SizedBox(height: spendly.spacing.x6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: spendly.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: spendly.radius.medium,
                  ),
                ),
                onPressed: onPrimaryAction,
                child: Text(
                  primaryActionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              SizedBox(height: spendly.spacing.x2),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    color: spendly.colors.primary,
                    fontWeight: FontWeight.bold,
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

class SpendlyErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const SpendlyErrorState({
    super.key,
    required this.title,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spendly.spacing.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: spendly.colors.error),
            SizedBox(height: spendly.spacing.x4),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spendly.spacing.x2),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(color: spendly.colors.neutral400),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: spendly.spacing.x6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: spendly.colors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: spendly.radius.medium,
                  ),
                ),
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SpendlyBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const SpendlyBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SpendlyTag extends StatelessWidget {
  final String text;
  final Color? color;

  const SpendlyTag({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = color ?? spendly.colors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x2, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: baseColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SpendlyPill extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const SpendlyPill({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x3, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? spendly.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? spendly.colors.primary : spendly.colors.neutral300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : spendly.colors.neutral600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SpendlyDivider extends StatelessWidget {
  const SpendlyDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF334155)
          : const Color(0xFFE5E7EB),
    );
  }
}

class SpendlyCalendarCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isCurrentMonth;
  final bool hasData;
  final Color? dotColor;
  final VoidCallback onTap;

  const SpendlyCalendarCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.hasData,
    this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? spendly.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isCurrentMonth
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900)
                        : spendly.colors.neutral400),
              ),
            ),
            if (hasData && !isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor ?? spendly.colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SpendlyListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SpendlyListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: spendly.colors.neutral400,
              ),
            )
          : null,
      trailing: trailing,
    );
  }
}

class SpendlyCategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const SpendlyCategoryChip({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final bg = isSelected ? color.withOpacity(0.15) : Colors.transparent;
    final borderCol = isSelected ? color : spendly.colors.neutral300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x3, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: spendly.spacing.x2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : spendly.colors.neutral600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
