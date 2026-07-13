import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'spendly_tokens.dart';

class AppTheme {
  static SpendlyThemeMode currentMode = SpendlyThemeMode.premium;

  // --- PREMIUM TOKENS ---
  static const _premiumColors = SpendlyColors(
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF818CF8),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF0EA5E9),
    income: Color(0xFF22C55E),
    savings: Color(0xFF34D399),
    expense: Color(0xFFEF4444),
    transfer: Color(0xFF8B5CF6),
    budget: Color(0xFF3B82F6),
    investment: Color(0xFF818CF8),
    neutralStatus: Color(0xFF9CA3AF),
    neutral50: Color(0xFFF9FAFB),
    neutral100: Color(0xFFF3F4F6),
    neutral200: Color(0xFFE5E7EB),
    neutral300: Color(0xFFD1D5DB),
    neutral400: Color(0xFF9CA3AF),
    neutral500: Color(0xFF6B7280),
    neutral600: Color(0xFF4B5563),
    neutral700: Color(0xFF374151),
    neutral800: Color(0xFF1F2937),
    neutral900: Color(0xFF111827),
  );

  static const _premiumSpacing = SpendlySpacing();
  
  static final _premiumRadius = SpendlyRadius(
    small: BorderRadius.circular(14),
    medium: BorderRadius.circular(16),
    large: BorderRadius.circular(24), // Cards and Charts
    xlarge: BorderRadius.circular(28),
    xxlarge: BorderRadius.circular(32), // Bottom Sheets
  );

  static const _premiumElevation = SpendlyElevation(
    surface0: [],
    surface1: [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))],
    surface2: [BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8))],
    surface3: [BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 16))],
    surface4: [BoxShadow(color: Color(0x26000000), blurRadius: 40, offset: Offset(0, 20))],
  );

  static const _premiumAnimation = SpendlyAnimation();
  static const _premiumIcons = SpendlyIcons();

  static const _premiumChartThemeLight = SpendlyChartTheme(
    grid: Color(0xFFE5E7EB),
    axis: Color(0xFF9CA3AF),
    tooltip: Color(0xFF111827),
    legend: Color(0xFF4B5563),
    label: Color(0xFF6B7280),
    selected: Color(0xFF4F46E5),
    hovered: Color(0xFF818CF8),
    chartBackground: Colors.transparent,
    categories: {
      'food': Color(0xFF10B981),
      'groceries': Color(0xFF84CC16),
      'petrol': Color(0xFF3B82F6),
      'fuel': Color(0xFF3B82F6),
      'recharges': Color(0xFF0EA5E9),
      'travel': Color(0xFF06B6D4),
      'gas': Color(0xFFF97316),
      'electricity': Color(0xFF8B5CF6),
      'utility': Color(0xFFD946EF),
      'medical': Color(0xFFEF4444),
      'insurances': Color(0xFF4F46E5),
      'shopping': Color(0xFFEC4899),
      'rent': Color(0xFF78350F),
      'bills': Color(0xFFF59E0B),
      'entertainment': Color(0xFFF43F5E),
      'education': Color(0xFF636AE8),
      'college': Color(0xFF312E81),
      'others': Color(0xFF9CA3AF),
    },
    fallbackCategoryColor: Color(0xFF9CA3AF),
  );

  static final _premiumChartThemeDark = _premiumChartThemeLight.copyWith(
    grid: const Color(0xFF374151),
    tooltip: const Color(0xFFF9FAFB),
    legend: const Color(0xFFD1D5DB),
  ) as SpendlyChartTheme;

  // --- LEGACY TOKENS (Fallback) ---
  static const _legacyColors = SpendlyColors(
    primary: Color(0xFF636AE8),
    secondary: Color(0xFF8C9EFF),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF3B82F6),
    income: Color(0xFF34D399),
    savings: Color(0xFF34D399),
    expense: Color(0xFFF87171),
    transfer: Color(0xFF8C9EFF),
    budget: Color(0xFFFBBF24),
    investment: Color(0xFF636AE8),
    neutralStatus: Color(0xFFCBD5E1),
    neutral50: Color(0xFFF8FAFC),
    neutral100: Color(0xFFF1F5F9),
    neutral200: Color(0xFFE2E8F0),
    neutral300: Color(0xFFCBD5E1),
    neutral400: Color(0xFF94A3B8),
    neutral500: Color(0xFF64748B),
    neutral600: Color(0xFF475569),
    neutral700: Color(0xFF334155),
    neutral800: Color(0xFF1E293B),
    neutral900: Color(0xFF0F172A),
  );

  static final _legacyRadius = SpendlyRadius(
    small: BorderRadius.circular(16),
    medium: BorderRadius.circular(20),
    large: BorderRadius.circular(24),
    xlarge: BorderRadius.circular(24),
    xxlarge: BorderRadius.circular(24),
  );

  static const _legacyElevation = SpendlyElevation(
    surface0: [],
    surface1: [],
    surface2: [],
    surface3: [],
    surface4: [],
  );

  static ThemeData get lightTheme {
    final isPremium = currentMode == SpendlyThemeMode.premium;
    final colors = isPremium ? _premiumColors : _legacyColors;
    final spacing = _premiumSpacing;
    final radius = isPremium ? _premiumRadius : _legacyRadius;
    final elevation = isPremium ? _premiumElevation : _legacyElevation;
    final chartTheme = isPremium ? _premiumChartThemeLight : _premiumChartThemeLight;
    
    final bg = isPremium ? const Color(0xFFF8FAFC) : const Color(0xFFF8FAFC);
    final cardBg = Colors.white;
    final borderCol = isPremium ? const Color(0xFFE5E7EB) : const Color(0xFFE2E8F0);

    final baseTextTheme = isPremium 
        ? GoogleFonts.interTextTheme() 
        : ThemeData.light().textTheme;
    
    final headerTextTheme = isPremium 
        ? GoogleFonts.outfitTextTheme(baseTextTheme) 
        : baseTextTheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.secondary,
        error: colors.error,
        background: bg,
      ),
      scaffoldBackgroundColor: bg,
      extensions: [
        SpendlyTheme(
          colors: colors,
          spacing: spacing,
          radius: radius,
          elevation: elevation,
          animation: _premiumAnimation,
          icons: _premiumIcons,
          charts: chartTheme,
        )
      ],
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius.large,
          side: BorderSide(color: borderCol, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: spacing.x8),
          shape: RoundedRectangleBorder(
            borderRadius: radius.medium,
          ),
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: EdgeInsets.all(spacing.x5),
        border: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.neutral500,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colors.neutral900,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.neutral900),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: headerTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.neutral900),
        headlineMedium: headerTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.neutral900),
        titleLarge: headerTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.neutral900),
        titleMedium: headerTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.neutral600),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.neutral700),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.neutral500),
      ),
    );
  }

  static ThemeData get darkTheme {
    final isPremium = currentMode == SpendlyThemeMode.premium;
    final colors = isPremium ? _premiumColors : _legacyColors;
    final spacing = _premiumSpacing;
    final radius = isPremium ? _premiumRadius : _legacyRadius;
    final elevation = isPremium ? _premiumElevation : _legacyElevation;
    final chartTheme = isPremium ? _premiumChartThemeDark : _premiumChartThemeDark;

    final bg = isPremium ? const Color(0xFF0F172A) : const Color(0xFF0F172A);
    final cardBg = isPremium ? const Color(0xFF111827) : const Color(0xFF1E293B);
    final borderCol = const Color(0xFF334155);

    final baseTextTheme = isPremium ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme) : ThemeData.dark().textTheme;
    final headerTextTheme = isPremium ? GoogleFonts.outfitTextTheme(baseTextTheme) : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.secondary,
        error: colors.error,
        background: bg,
      ),
      scaffoldBackgroundColor: bg,
      extensions: [
        SpendlyTheme(
          colors: colors,
          spacing: spacing,
          radius: radius,
          elevation: elevation,
          animation: _premiumAnimation,
          icons: _premiumIcons,
          charts: chartTheme,
        )
      ],
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius.large,
          side: BorderSide(color: borderCol, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: spacing.x8),
          shape: RoundedRectangleBorder(
            borderRadius: radius.medium,
          ),
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: EdgeInsets.symmetric(vertical: spacing.x5, horizontal: spacing.x6),
        border: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius.small,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.neutral400,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headerTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: headerTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: headerTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: headerTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: headerTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.neutral300),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.neutral200),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.neutral400),
      ),
    );
  }
}
