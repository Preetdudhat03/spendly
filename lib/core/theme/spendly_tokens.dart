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
  // --- PRIMARY BRAND TOKENS ---
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryLight;
  final LinearGradient primaryGradient;
  final Color primaryGlow;

  // --- SURFACES & BACKGROUNDS ---
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color cardSurface;
  final Color elevatedSurface;
  final Color modalSurface;
  final Color navigationBar;
  final Color floatingNavigation;
  final Color inputBackground;
  final Color disabledBackground;

  // --- BORDERS & DIVIDERS ---
  final Color divider;
  final Color border;
  final Color outline;

  // --- TEXT TOKENS ---
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textHint;
  final Color textInverse;

  // --- STATUS TOKENS ---
  final Color success;
  final Color successBackground;
  final Color successDark;
  final Color warning;
  final Color warningBackground;
  final Color warningDark;
  final Color error;
  final Color errorBackground;
  final Color errorDark;
  final Color info;
  final Color infoBackground;
  final Color infoDark;

  // --- INPUT TOKENS ---
  final Color inputNormalBorder;
  final Color inputFocusedBorder;
  final Color inputFocusedShadow;
  final Color inputPlaceholder;
  final Color inputCursor;
  final Color inputSelection;

  // --- BUTTON TOKENS ---
  final Color buttonPrimaryBg;
  final Color buttonPrimaryText;
  final Color buttonPrimaryHover;
  final Color buttonPrimaryPressed;
  final Color buttonPrimaryDisabled;
  final Color buttonSecondaryBorder;
  final Color buttonSecondaryText;
  final Color buttonGhostText;
  final Color buttonDangerBg;
  final Color buttonDangerText;

  // --- FLOATING NAV TOKENS ---
  final Color navBg;
  final Color navSelectedPill;
  final Color navSelectedIcon;
  final Color navUnselectedIcon;
  final Color navDivider;
  final Color navShadow;
  final Color navFab;
  final Color navFabIcon;
  final Color navFabShadow;

  // --- PROGRESS BARS ---
  final Color progressBudgetSafe;
  final Color progressNearLimit;
  final Color progressExceeded;
  final Color progressTrack;

  // --- HEATMAP ---
  final Color heatmapNoExpense;
  final Color heatmapLow;
  final Color heatmapMedium;
  final Color heatmapHigh;
  final Color heatmapVeryHigh;

  // --- CALENDAR ---
  final Color calendarSelectedDate;
  final Color calendarTodayRing;

  // --- FINANCIAL STATES (Backwards Compatibility) ---
  final Color secondary;
  final Color income;
  final Color savings;
  final Color expense;
  final Color transfer;
  final Color budget;
  final Color investment;
  final Color neutralStatus;

  // --- NEUTRALS SCALE ---
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
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryLight,
    required this.primaryGradient,
    required this.primaryGlow,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.cardSurface,
    required this.elevatedSurface,
    required this.modalSurface,
    required this.navigationBar,
    required this.floatingNavigation,
    required this.inputBackground,
    required this.disabledBackground,
    required this.divider,
    required this.border,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textHint,
    required this.textInverse,
    required this.success,
    required this.successBackground,
    required this.successDark,
    required this.warning,
    required this.warningBackground,
    required this.warningDark,
    required this.error,
    required this.errorBackground,
    required this.errorDark,
    required this.info,
    required this.infoBackground,
    required this.infoDark,
    required this.inputNormalBorder,
    required this.inputFocusedBorder,
    required this.inputFocusedShadow,
    required this.inputPlaceholder,
    required this.inputCursor,
    required this.inputSelection,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryText,
    required this.buttonPrimaryHover,
    required this.buttonPrimaryPressed,
    required this.buttonPrimaryDisabled,
    required this.buttonSecondaryBorder,
    required this.buttonSecondaryText,
    required this.buttonGhostText,
    required this.buttonDangerBg,
    required this.buttonDangerText,
    required this.navBg,
    required this.navSelectedPill,
    required this.navSelectedIcon,
    required this.navUnselectedIcon,
    required this.navDivider,
    required this.navShadow,
    required this.navFab,
    required this.navFabIcon,
    required this.navFabShadow,
    required this.progressBudgetSafe,
    required this.progressNearLimit,
    required this.progressExceeded,
    required this.progressTrack,
    required this.heatmapNoExpense,
    required this.heatmapLow,
    required this.heatmapMedium,
    required this.heatmapHigh,
    required this.heatmapVeryHigh,
    required this.calendarSelectedDate,
    required this.calendarTodayRing,
    required this.secondary,
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
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryLight,
    LinearGradient? primaryGradient,
    Color? primaryGlow,
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? cardSurface,
    Color? elevatedSurface,
    Color? modalSurface,
    Color? navigationBar,
    Color? floatingNavigation,
    Color? inputBackground,
    Color? disabledBackground,
    Color? divider,
    Color? border,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textHint,
    Color? textInverse,
    Color? success,
    Color? successBackground,
    Color? successDark,
    Color? warning,
    Color? warningBackground,
    Color? warningDark,
    Color? error,
    Color? errorBackground,
    Color? errorDark,
    Color? info,
    Color? infoBackground,
    Color? infoDark,
    Color? inputNormalBorder,
    Color? inputFocusedBorder,
    Color? inputFocusedShadow,
    Color? inputPlaceholder,
    Color? inputCursor,
    Color? inputSelection,
    Color? buttonPrimaryBg,
    Color? buttonPrimaryText,
    Color? buttonPrimaryHover,
    Color? buttonPrimaryPressed,
    Color? buttonPrimaryDisabled,
    Color? buttonSecondaryBorder,
    Color? buttonSecondaryText,
    Color? buttonGhostText,
    Color? buttonDangerBg,
    Color? buttonDangerText,
    Color? navBg,
    Color? navSelectedPill,
    Color? navSelectedIcon,
    Color? navUnselectedIcon,
    Color? navDivider,
    Color? navShadow,
    Color? navFab,
    Color? navFabIcon,
    Color? navFabShadow,
    Color? progressBudgetSafe,
    Color? progressNearLimit,
    Color? progressExceeded,
    Color? progressTrack,
    Color? heatmapNoExpense,
    Color? heatmapLow,
    Color? heatmapMedium,
    Color? heatmapHigh,
    Color? heatmapVeryHigh,
    Color? calendarSelectedDate,
    Color? calendarTodayRing,
    Color? secondary,
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
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      cardSurface: cardSurface ?? this.cardSurface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      modalSurface: modalSurface ?? this.modalSurface,
      navigationBar: navigationBar ?? this.navigationBar,
      floatingNavigation: floatingNavigation ?? this.floatingNavigation,
      inputBackground: inputBackground ?? this.inputBackground,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textHint: textHint ?? this.textHint,
      textInverse: textInverse ?? this.textInverse,
      success: success ?? this.success,
      successBackground: successBackground ?? this.successBackground,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      warningBackground: warningBackground ?? this.warningBackground,
      warningDark: warningDark ?? this.warningDark,
      error: error ?? this.error,
      errorBackground: errorBackground ?? this.errorBackground,
      errorDark: errorDark ?? this.errorDark,
      info: info ?? this.info,
      infoBackground: infoBackground ?? this.infoBackground,
      infoDark: infoDark ?? this.infoDark,
      inputNormalBorder: inputNormalBorder ?? this.inputNormalBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      inputFocusedShadow: inputFocusedShadow ?? this.inputFocusedShadow,
      inputPlaceholder: inputPlaceholder ?? this.inputPlaceholder,
      inputCursor: inputCursor ?? this.inputCursor,
      inputSelection: inputSelection ?? this.inputSelection,
      buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
      buttonPrimaryText: buttonPrimaryText ?? this.buttonPrimaryText,
      buttonPrimaryHover: buttonPrimaryHover ?? this.buttonPrimaryHover,
      buttonPrimaryPressed: buttonPrimaryPressed ?? this.buttonPrimaryPressed,
      buttonPrimaryDisabled: buttonPrimaryDisabled ?? this.buttonPrimaryDisabled,
      buttonSecondaryBorder: buttonSecondaryBorder ?? this.buttonSecondaryBorder,
      buttonSecondaryText: buttonSecondaryText ?? this.buttonSecondaryText,
      buttonGhostText: buttonGhostText ?? this.buttonGhostText,
      buttonDangerBg: buttonDangerBg ?? this.buttonDangerBg,
      buttonDangerText: buttonDangerText ?? this.buttonDangerText,
      navBg: navBg ?? this.navBg,
      navSelectedPill: navSelectedPill ?? this.navSelectedPill,
      navSelectedIcon: navSelectedIcon ?? this.navSelectedIcon,
      navUnselectedIcon: navUnselectedIcon ?? this.navUnselectedIcon,
      navDivider: navDivider ?? this.navDivider,
      navShadow: navShadow ?? this.navShadow,
      navFab: navFab ?? this.navFab,
      navFabIcon: navFabIcon ?? this.navFabIcon,
      navFabShadow: navFabShadow ?? this.navFabShadow,
      progressBudgetSafe: progressBudgetSafe ?? this.progressBudgetSafe,
      progressNearLimit: progressNearLimit ?? this.progressNearLimit,
      progressExceeded: progressExceeded ?? this.progressExceeded,
      progressTrack: progressTrack ?? this.progressTrack,
      heatmapNoExpense: heatmapNoExpense ?? this.heatmapNoExpense,
      heatmapLow: heatmapLow ?? this.heatmapLow,
      heatmapMedium: heatmapMedium ?? this.heatmapMedium,
      heatmapHigh: heatmapHigh ?? this.heatmapHigh,
      heatmapVeryHigh: heatmapVeryHigh ?? this.heatmapVeryHigh,
      calendarSelectedDate: calendarSelectedDate ?? this.calendarSelectedDate,
      calendarTodayRing: calendarTodayRing ?? this.calendarTodayRing,
      secondary: secondary ?? this.secondary,
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
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      navigationBar: Color.lerp(navigationBar, other.navigationBar, t)!,
      floatingNavigation: Color.lerp(floatingNavigation, other.floatingNavigation, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      disabledBackground: Color.lerp(disabledBackground, other.disabledBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBackground: Color.lerp(successBackground, other.successBackground, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground: Color.lerp(warningBackground, other.warningBackground, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoDark: Color.lerp(infoDark, other.infoDark, t)!,
      inputNormalBorder: Color.lerp(inputNormalBorder, other.inputNormalBorder, t)!,
      inputFocusedBorder: Color.lerp(inputFocusedBorder, other.inputFocusedBorder, t)!,
      inputFocusedShadow: Color.lerp(inputFocusedShadow, other.inputFocusedShadow, t)!,
      inputPlaceholder: Color.lerp(inputPlaceholder, other.inputPlaceholder, t)!,
      inputCursor: Color.lerp(inputCursor, other.inputCursor, t)!,
      inputSelection: Color.lerp(inputSelection, other.inputSelection, t)!,
      buttonPrimaryBg: Color.lerp(buttonPrimaryBg, other.buttonPrimaryBg, t)!,
      buttonPrimaryText: Color.lerp(buttonPrimaryText, other.buttonPrimaryText, t)!,
      buttonPrimaryHover: Color.lerp(buttonPrimaryHover, other.buttonPrimaryHover, t)!,
      buttonPrimaryPressed: Color.lerp(buttonPrimaryPressed, other.buttonPrimaryPressed, t)!,
      buttonPrimaryDisabled: Color.lerp(buttonPrimaryDisabled, other.buttonPrimaryDisabled, t)!,
      buttonSecondaryBorder: Color.lerp(buttonSecondaryBorder, other.buttonSecondaryBorder, t)!,
      buttonSecondaryText: Color.lerp(buttonSecondaryText, other.buttonSecondaryText, t)!,
      buttonGhostText: Color.lerp(buttonGhostText, other.buttonGhostText, t)!,
      buttonDangerBg: Color.lerp(buttonDangerBg, other.buttonDangerBg, t)!,
      buttonDangerText: Color.lerp(buttonDangerText, other.buttonDangerText, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navSelectedPill: Color.lerp(navSelectedPill, other.navSelectedPill, t)!,
      navSelectedIcon: Color.lerp(navSelectedIcon, other.navSelectedIcon, t)!,
      navUnselectedIcon: Color.lerp(navUnselectedIcon, other.navUnselectedIcon, t)!,
      navDivider: Color.lerp(navDivider, other.navDivider, t)!,
      navShadow: Color.lerp(navShadow, other.navShadow, t)!,
      navFab: Color.lerp(navFab, other.navFab, t)!,
      navFabIcon: Color.lerp(navFabIcon, other.navFabIcon, t)!,
      navFabShadow: Color.lerp(navFabShadow, other.navFabShadow, t)!,
      progressBudgetSafe: Color.lerp(progressBudgetSafe, other.progressBudgetSafe, t)!,
      progressNearLimit: Color.lerp(progressNearLimit, other.progressNearLimit, t)!,
      progressExceeded: Color.lerp(progressExceeded, other.progressExceeded, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      heatmapNoExpense: Color.lerp(heatmapNoExpense, other.heatmapNoExpense, t)!,
      heatmapLow: Color.lerp(heatmapLow, other.heatmapLow, t)!,
      heatmapMedium: Color.lerp(heatmapMedium, other.heatmapMedium, t)!,
      heatmapHigh: Color.lerp(heatmapHigh, other.heatmapHigh, t)!,
      heatmapVeryHigh: Color.lerp(heatmapVeryHigh, other.heatmapVeryHigh, t)!,
      calendarSelectedDate: Color.lerp(calendarSelectedDate, other.calendarSelectedDate, t)!,
      calendarTodayRing: Color.lerp(calendarTodayRing, other.calendarTodayRing, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
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

class SpendlyCategoryStyle {
  final Color color;
  final Color iconBackground;
  final Color iconColor;
  final Color chipBackground;
  final Color graphColor;

  SpendlyCategoryStyle(this.color)
      : iconBackground = color.withOpacity(0.15),
        iconColor = color,
        chipBackground = color.withOpacity(0.12),
        graphColor = color;
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
  final List<Color> sequentialPalette;
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
    required this.sequentialPalette,
    required this.categories,
    required this.fallbackCategoryColor,
  });

  Color getCategoryColor(String category) {
    return categories[category.toLowerCase()] ?? fallbackCategoryColor;
  }

  SpendlyCategoryStyle getCategoryStyle(String category) {
    return SpendlyCategoryStyle(getCategoryColor(category));
  }

  @override
  ThemeExtension<SpendlyChartTheme> copyWith({
    Color? grid,
    Color? axis,
    Color? tooltip,
    Color? legend,
    Color? label,
    Color? selected,
    Color? hovered,
    Color? chartBackground,
    List<Color>? sequentialPalette,
    Map<String, Color>? categories,
    Color? fallbackCategoryColor,
  }) {
    return SpendlyChartTheme(
      grid: grid ?? this.grid,
      axis: axis ?? this.axis,
      tooltip: tooltip ?? this.tooltip,
      legend: legend ?? this.legend,
      label: label ?? this.label,
      selected: selected ?? this.selected,
      hovered: hovered ?? this.hovered,
      chartBackground: chartBackground ?? this.chartBackground,
      sequentialPalette: sequentialPalette ?? this.sequentialPalette,
      categories: categories ?? this.categories,
      fallbackCategoryColor: fallbackCategoryColor ?? this.fallbackCategoryColor,
    );
  }

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
      sequentialPalette: sequentialPalette,
      categories: categories,
      fallbackCategoryColor: Color.lerp(fallbackCategoryColor, other.fallbackCategoryColor, t)!,
    );
  }
}
