import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

enum SpendlyButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  text,
  danger,
  success,
}

enum SpendlyButtonSize {
  small,
  medium,
  large,
}

class SpendlyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SpendlyButtonVariant variant;
  final SpendlyButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  const SpendlyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SpendlyButtonVariant.primary,
    this.size = SpendlyButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final isDisabled = onPressed == null || isLoading;

    // Resolve color scheme based on variant
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case SpendlyButtonVariant.primary:
        bg = spendly.colors.primary;
        fg = Colors.white;
        break;
      case SpendlyButtonVariant.secondary:
        bg = theme.brightness == Brightness.dark
            ? spendly.colors.neutral800
            : spendly.colors.neutral100;
        fg = theme.brightness == Brightness.dark
            ? spendly.colors.neutral100
            : spendly.colors.neutral800;
        break;
      case SpendlyButtonVariant.outlined:
        bg = Colors.transparent;
        fg = spendly.colors.primary;
        border = BorderSide(color: spendly.colors.primary, width: 1.5);
        break;
      case SpendlyButtonVariant.ghost:
        bg = Colors.transparent;
        fg = theme.brightness == Brightness.dark
            ? spendly.colors.neutral300
            : spendly.colors.neutral700;
        break;
      case SpendlyButtonVariant.text:
        bg = Colors.transparent;
        fg = spendly.colors.primary;
        break;
      case SpendlyButtonVariant.danger:
        bg = spendly.colors.error;
        fg = Colors.white;
        break;
      case SpendlyButtonVariant.success:
        bg = spendly.colors.success;
        fg = Colors.white;
        break;
    }

    if (isDisabled) {
      bg = theme.brightness == Brightness.dark
          ? spendly.colors.neutral800.withOpacity(0.5)
          : spendly.colors.neutral200;
      fg = spendly.colors.neutral400;
      border = BorderSide.none;
    }

    // Resolve padding and font sizes based on button size
    double verticalPadding;
    double horizontalPadding;
    double fontSize;
    double height;

    switch (size) {
      case SpendlyButtonSize.small:
        verticalPadding = spendly.spacing.x2;
        horizontalPadding = spendly.spacing.x4;
        fontSize = 13;
        height = 36;
        break;
      case SpendlyButtonSize.medium:
        verticalPadding = spendly.spacing.x3;
        horizontalPadding = spendly.spacing.x5;
        fontSize = 15;
        height = 46;
        break;
      case SpendlyButtonSize.large:
        verticalPadding = spendly.spacing.x4;
        horizontalPadding = spendly.spacing.x6;
        fontSize = 16;
        height = 54;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          SizedBox(width: spendly.spacing.x2),
        ] else if (icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: fg, size: fontSize + 4),
            child: icon!,
          ),
          SizedBox(width: spendly.spacing.x2),
        ],
        Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: spendly.animation.fast,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: spendly.radius.medium,
            side: border,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            highlightColor: fg.withOpacity(0.05),
            splashColor: fg.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class SpendlyFAB extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final String? label;

  const SpendlyFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;

    final shape = RoundedRectangleBorder(
      borderRadius: spendly.radius.xlarge,
    );

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: spendly.colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: shape,
        icon: icon,
        label: Text(
          label!,
          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: spendly.colors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: shape,
      child: icon,
    );
  }
}
