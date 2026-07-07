import 'package:flutter/material.dart';

enum SpendlyThemeMode {
  legacy,
  premium,
}

/// Helper extension to access the design tokens easily.
extension SpendlyThemeExtension on BuildContext {
  SpendlyTheme get spendly => Theme.of(this).extension<SpendlyTheme>()!;
}

/// A container for all the Spendly design extensions to allow `context.spendly.colors`, etc.
class SpendlyTheme extends ThemeExtension<SpendlyTheme> {
  final SpendlyColors colors;
  final SpendlySpacing spacing;
  final SpendlyRadius radius;
  final SpendlyElevation elevation;
  final SpendlyAnimation animation;
  final SpendlyIcons icons;
  final SpendlyChartTheme charts;

  const SpendlyTheme({
    required this.colors,
    required this.spacing,
    required this.radius,
    required this.elevation,
    required this.animation,
    required this.icons,
    required this.charts,
  });

  @override
  ThemeExtension<SpendlyTheme> copyWith({
    SpendlyColors? colors,
    SpendlySpacing? spacing,
    SpendlyRadius? radius,
    SpendlyElevation? elevation,
    SpendlyAnimation? animation,
    SpendlyIcons? icons,
    SpendlyChartTheme? charts,
  }) {
    return SpendlyTheme(
      colors: colors ?? this.colors,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      elevation: elevation ?? this.elevation,
      animation: animation ?? this.animation,
      icons: icons ?? this.icons,
      charts: charts ?? this.charts,
    );
  }

  @override
  ThemeExtension<SpendlyTheme> lerp(covariant ThemeExtension<SpendlyTheme>? other, double t) {
    if (other is! SpendlyTheme) return this;
    return SpendlyTheme(
      colors: colors.lerp(other.colors, t) as SpendlyColors,
      spacing: spacing.lerp(other.spacing, t) as SpendlySpacing,
      radius: radius.lerp(other.radius, t) as SpendlyRadius,
      elevation: elevation.lerp(other.elevation, t) as SpendlyElevation,
      animation: animation.lerp(other.animation, t) as SpendlyAnimation,
      icons: icons.lerp(other.icons, t) as SpendlyIcons,
      charts: charts.lerp(other.charts, t) as SpendlyChartTheme,
    );
  }
}

class SpendlyColors extends ThemeExtension<SpendlyColors> {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Financial States
  final Color income;
  final Color savings;
  final Color expense;
  final Color transfer;
  final Color budget;
  final Color investment;
  final Color neutralStatus;

  // Neutrals Scale
  final Color neutral50;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;

  const SpendlyColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.income,
    required this.savings,
    required this.expense,
    required this.transfer,
    required this.budget,
    required this.investment,
    required this.neutralStatus,
    required this.neutral50,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
  });

  @override
  ThemeExtension<SpendlyColors> copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? income,
    Color? savings,
    Color? expense,
    Color? transfer,
    Color? budget,
    Color? investment,
    Color? neutralStatus,
    Color? neutral50,
    Color? neutral100,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? neutral900,
  }) {
    return SpendlyColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      income: income ?? this.income,
      savings: savings ?? this.savings,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      budget: budget ?? this.budget,
      investment: investment ?? this.investment,
      neutralStatus: neutralStatus ?? this.neutralStatus,
      neutral50: neutral50 ?? this.neutral50,
      neutral100: neutral100 ?? this.neutral100,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      neutral900: neutral900 ?? this.neutral900,
    );
  }

  @override
  ThemeExtension<SpendlyColors> lerp(covariant ThemeExtension<SpendlyColors>? other, double t) {
    if (other is! SpendlyColors) return this;
    return SpendlyColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      income: Color.lerp(income, other.income, t)!,
      savings: Color.lerp(savings, other.savings, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      budget: Color.lerp(budget, other.budget, t)!,
      investment: Color.lerp(investment, other.investment, t)!,
      neutralStatus: Color.lerp(neutralStatus, other.neutralStatus, t)!,
      neutral50: Color.lerp(neutral50, other.neutral50, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
    );
  }
}

class SpendlySpacing extends ThemeExtension<SpendlySpacing> {
  final double x1; // 4
  final double x2; // 8
  final double x3; // 12
  final double x4; // 16
  final double x5; // 20
  final double x6; // 24
  final double x8; // 32
  final double x10; // 40
  final double x12; // 48
  final double x16; // 64

  const SpendlySpacing({
    this.x1 = 4,
    this.x2 = 8,
    this.x3 = 12,
    this.x4 = 16,
    this.x5 = 20,
    this.x6 = 24,
    this.x8 = 32,
    this.x10 = 40,
    this.x12 = 48,
    this.x16 = 64,
  });

  @override
  ThemeExtension<SpendlySpacing> copyWith() => this;

  @override
  ThemeExtension<SpendlySpacing> lerp(covariant ThemeExtension<SpendlySpacing>? other, double t) => this;
}

class SpendlyRadius extends ThemeExtension<SpendlyRadius> {
  final BorderRadius small; // 14
  final BorderRadius medium; // 16
  final BorderRadius large; // 20
  final BorderRadius xlarge; // 24
  final BorderRadius xxlarge; // 32

  const SpendlyRadius({
    required this.small,
    required this.medium,
    required this.large,
    required this.xlarge,
    required this.xxlarge,
  });

  @override
  ThemeExtension<SpendlyRadius> copyWith() => this;

  @override
  ThemeExtension<SpendlyRadius> lerp(covariant ThemeExtension<SpendlyRadius>? other, double t) {
    if (other is! SpendlyRadius) return this;
    return SpendlyRadius(
      small: BorderRadius.lerp(small, other.small, t)!,
      medium: BorderRadius.lerp(medium, other.medium, t)!,
      large: BorderRadius.lerp(large, other.large, t)!,
      xlarge: BorderRadius.lerp(xlarge, other.xlarge, t)!,
      xxlarge: BorderRadius.lerp(xxlarge, other.xxlarge, t)!,
    );
  }
}

class SpendlyElevation extends ThemeExtension<SpendlyElevation> {
  final List<BoxShadow>? surface0;
  final List<BoxShadow>? surface1;
  final List<BoxShadow>? surface2;
  final List<BoxShadow>? surface3;
  final List<BoxShadow>? surface4;

  const SpendlyElevation({
    this.surface0,
    this.surface1,
    this.surface2,
    this.surface3,
    this.surface4,
  });

  @override
  ThemeExtension<SpendlyElevation> copyWith() => this;

  @override
  ThemeExtension<SpendlyElevation> lerp(covariant ThemeExtension<SpendlyElevation>? other, double t) {
    if (other is! SpendlyElevation) return this;
    return SpendlyElevation(
      surface0: BoxShadow.lerpList(surface0, other.surface0, t),
      surface1: BoxShadow.lerpList(surface1, other.surface1, t),
      surface2: BoxShadow.lerpList(surface2, other.surface2, t),
      surface3: BoxShadow.lerpList(surface3, other.surface3, t),
      surface4: BoxShadow.lerpList(surface4, other.surface4, t),
    );
  }
}

class SpendlyAnimation extends ThemeExtension<SpendlyAnimation> {
  final Duration fast; // 150ms
  final Duration medium; // 250ms
  final Duration slow; // 400ms
  final Curve easeOut;
  final Curve spring;

  const SpendlyAnimation({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
    this.easeOut = Curves.easeOut,
    this.spring = Curves.elasticOut,
  });

  @override
  ThemeExtension<SpendlyAnimation> copyWith() => this;

  @override
  ThemeExtension<SpendlyAnimation> lerp(covariant ThemeExtension<SpendlyAnimation>? other, double t) => this;
}

class SpendlyIcons extends ThemeExtension<SpendlyIcons> {
  final double s16;
  final double s18;
  final double s20;
  final double s24;

  const SpendlyIcons({
    this.s16 = 16,
    this.s18 = 18,
    this.s20 = 20,
    this.s24 = 24,
  });

  @override
  ThemeExtension<SpendlyIcons> copyWith() => this;
  @override
  ThemeExtension<SpendlyIcons> lerp(covariant ThemeExtension<SpendlyIcons>? other, double t) => this;
}

class SpendlyChartTheme extends ThemeExtension<SpendlyChartTheme> {
  final Color grid;
  final Color axis;
  final Color tooltip;
  final Color legend;
  final Color label;
  final Color selected;
  final Color hovered;
  final Color chartBackground;
  
  final Map<String, Color> categories;
  final Color fallbackCategoryColor;

  const SpendlyChartTheme({
    required this.grid,
    required this.axis,
    required this.tooltip,
    required this.legend,
    required this.label,
    required this.selected,
    required this.hovered,
    required this.chartBackground,
    required this.categories,
    required this.fallbackCategoryColor,
  });

  Color getCategoryColor(String category) {
    return categories[category.toLowerCase()] ?? fallbackCategoryColor;
  }

  @override
  ThemeExtension<SpendlyChartTheme> copyWith() => this;

  @override
  ThemeExtension<SpendlyChartTheme> lerp(covariant ThemeExtension<SpendlyChartTheme>? other, double t) {
    if (other is! SpendlyChartTheme) return this;
    return SpendlyChartTheme(
      grid: Color.lerp(grid, other.grid, t)!,
      axis: Color.lerp(axis, other.axis, t)!,
      tooltip: Color.lerp(tooltip, other.tooltip, t)!,
      legend: Color.lerp(legend, other.legend, t)!,
      label: Color.lerp(label, other.label, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      hovered: Color.lerp(hovered, other.hovered, t)!,
      chartBackground: Color.lerp(chartBackground, other.chartBackground, t)!,
      categories: categories,
      fallbackCategoryColor: Color.lerp(fallbackCategoryColor, other.fallbackCategoryColor, t)!,
    );
  }
}
