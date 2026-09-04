import 'package:flutter/material.dart';

/// Reusable floating solid capsule header widget matching Spendly's premium fintech design language.
class CapsuleHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final String? badge;
  final Color? iconColor;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const CapsuleHeader({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.trailing,
    this.badge,
    this.iconColor,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIconColor = iconColor ??
        (isDark ? const Color(0xFF818CF8) : colorScheme.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          constraints: const BoxConstraints(
            minHeight: 40,
            maxWidth: 340,
          ),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(100),
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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: effectiveIconColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? colorScheme.primary)
                        .withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to build a standard transparent AppBar containing a CapsuleHeader
AppBar buildCapsuleAppBar({
  required BuildContext context,
  required String title,
  IconData? icon,
  Widget? leading,
  Widget? trailing,
  String? badge,
  Color? iconColor,
  Color? badgeColor,
  VoidCallback? onTap,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    title: CapsuleHeader(
      title: title,
      icon: icon,
      trailing: trailing,
      badge: badge,
      iconColor: iconColor,
      badgeColor: badgeColor,
      onTap: onTap,
    ),
    actions: actions,
  );
}
