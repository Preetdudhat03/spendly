import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'spendly_tokens.dart';

class AppTheme {
  static SpendlyThemeMode currentMode = SpendlyThemeMode.premium;

  // ====================================================
  // LIGHT DESIGN TOKENS
  // ====================================================
  static const _lightColors = SpendlyColors(
    // Primary Brand
    primary: Color(0xFF4F46E5),
    primaryHover: Color(0xFF4338CA),
    primaryPressed: Color(0xFF3730A3),
    primaryLight: Color(0xFF818CF8),
    primaryGradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
    primaryGlow: Color(0x2E4F46E5),

    // Surfaces & Backgrounds
    backgroundPrimary: Color(0xFFF8FAFC),
    backgroundSecondary: Color(0xFFF1F5F9),
    cardSurface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFFFFFFF),
    modalSurface: Color(0xFFFFFFFF),
    navigationBar: Color(0xFFFFFFFF),
    floatingNavigation: Color(0xEBFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    disabledBackground: Color(0xFFF3F4F6),

    // Borders & Dividers
    divider: Color(0xFFE2E8F0),
    border: Color(0xFFCBD5E1),
    outline: Color(0xFF94A3B8),

    // Text Colors
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF64748B),
    textDisabled: Color(0xFF94A3B8),
    textHint: Color(0xFF9CA3AF),
    textInverse: Color(0xFFFFFFFF),

    // Status Colors
    success: Color(0xFF22C55E),
    successBackground: Color(0xFFDCFCE7),
    successDark: Color(0xFF14532D),
    warning: Color(0xFFF59E0B),
    warningBackground: Color(0xFFFEF3C7),
    warningDark: Color(0xFF78350F),
    error: Color(0xFFEF4444),
    errorBackground: Color(0xFFFEE2E2),
    errorDark: Color(0xFF7F1D1D),
    info: Color(0xFF3B82F6),
    infoBackground: Color(0xFFDBEAFE),
    infoDark: Color(0xFF1E3A8A),

    // Input Colors
    inputNormalBorder: Color(0xFFCBD5E1),
    inputFocusedBorder: Color(0xFF4F46E5),
    inputFocusedShadow: Color(0x2E4F46E5),
    inputPlaceholder: Color(0xFF94A3B8),
    inputCursor: Color(0xFF4F46E5),
    inputSelection: Color(0xFFC7D2FE),

    // Button Colors
    buttonPrimaryBg: Color(0xFF4F46E5),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonPrimaryHover: Color(0xFF4338CA),
    buttonPrimaryPressed: Color(0xFF3730A3),
    buttonPrimaryDisabled: Color(0xFFA5B4FC),
    buttonSecondaryBorder: Color(0xFF4F46E5),
    buttonSecondaryText: Color(0xFF4F46E5),
    buttonGhostText: Color(0xFF4F46E5),
    buttonDangerBg: Color(0xFFEF4444),
    buttonDangerText: Color(0xFFFFFFFF),

    // Floating Navigation
    navBg: Color(0xEBFFFFFF),
    navSelectedPill: Color(0xFFEEF2FF),
    navSelectedIcon: Color(0xFF4F46E5),
    navUnselectedIcon: Color(0xFF64748B),
    navDivider: Colors.transparent,
    navShadow: Color(0x140F172A),
    navFab: Color(0xFF4F46E5),
    navFabIcon: Color(0xFFFFFFFF),
    navFabShadow: Color(0x2E4F46E5),

    // Progress Bars
    progressBudgetSafe: Color(0xFF22C55E),
    progressNearLimit: Color(0xFFF59E0B),
    progressExceeded: Color(0xFFEF4444),
    progressTrack: Color(0xFFE2E8F0),

    // Heatmap
    heatmapNoExpense: Color(0xFFF1F5F9),
    heatmapLow: Color(0xFF2E5AAC),
    heatmapMedium: Color(0xFF4F46E5),
    heatmapHigh: Color(0xFF7C3AED),
    heatmapVeryHigh: Color(0xFFA855F7),

    // Calendar
    calendarSelectedDate: Color(0xFF4F46E5),
    calendarTodayRing: Color(0xFF818CF8),

    // Financial States (Backwards Compatibility)
    secondary: Color(0xFF818CF8),
    income: Color(0xFF22C55E),
    savings: Color(0xFF10B981),
    expense: Color(0xFFEF4444),
    transfer: Color(0xFF8B5CF6),
    budget: Color(0xFF3B82F6),
    investment: Color(0xFF6366F1),
    neutralStatus: Color(0xFF94A3B8),

    // Neutrals Scale
    neutral50: Color(0xFFF8FAFC),
    neutral100: Color(0xFFF1F5F9),
    neutral200: Color(0xFFE2E8F0),
    neutral300: Color(0xFFCBD5E1),
    neutral400: Color(0xFF94A3B8),
    neutral500: Color(0xFF64748B),
    neutral600: Color(0xFF475569),
    neutral700: Color(0xFF334155),
    neutral800: Color(0xFF1E293B),
    neutral900: Color(0xFF111827),
  );

  // ====================================================
  // DARK DESIGN TOKENS
  // ====================================================
  static const _darkColors = SpendlyColors(
    // Primary Brand
    primary: Color(0xFF4F46E5),
    primaryHover: Color(0xFF4338CA),
    primaryPressed: Color(0xFF3730A3),
    primaryLight: Color(0xFF818CF8),
    primaryGradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
    primaryGlow: Color(0x2E4F46E5),

    // Surfaces & Backgrounds
    backgroundPrimary: Color(0xFF0B1220),
    backgroundSecondary: Color(0xFF111827),
    cardSurface: Color(0xFF172033),
    elevatedSurface: Color(0xFF1E293B),
    modalSurface: Color(0xFF1F2937),
    navigationBar: Color(0xFF111827),
    floatingNavigation: Color(0xF5172033),
    inputBackground: Color(0xFF182334),
    disabledBackground: Color(0xFF1F2937),

    // Borders & Dividers
    divider: Color(0xFF243147),
    border: Color(0xFF2D3A52),
    outline: Color(0xFF334155),

    // Text Colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFF94A3B8),
    textDisabled: Color(0xFF64748B),
    textHint: Color(0xFF6B7280),
    textInverse: Color(0xFF111827),

    // Status Colors
    success: Color(0xFF22C55E),
    successBackground: Color(0xFFDCFCE7),
    successDark: Color(0xFF14532D),
    warning: Color(0xFFF59E0B),
    warningBackground: Color(0xFFFEF3C7),
    warningDark: Color(0xFF78350F),
    error: Color(0xFFEF4444),
    errorBackground: Color(0xFFFEE2E2),
    errorDark: Color(0xFF7F1D1D),
    info: Color(0xFF3B82F6),
    infoBackground: Color(0xFFDBEAFE),
    infoDark: Color(0xFF1E3A8A),

    // Input Colors
    inputNormalBorder: Color(0xFF2D3A52),
    inputFocusedBorder: Color(0xFF4F46E5),
    inputFocusedShadow: Color(0x2E4F46E5),
    inputPlaceholder: Color(0xFF6B7280),
    inputCursor: Color(0xFF4F46E5),
    inputSelection: Color(0xFFC7D2FE),

    // Button Colors
    buttonPrimaryBg: Color(0xFF4F46E5),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonPrimaryHover: Color(0xFF4338CA),
    buttonPrimaryPressed: Color(0xFF3730A3),
    buttonPrimaryDisabled: Color(0xFFA5B4FC),
    buttonSecondaryBorder: Color(0xFF4F46E5),
    buttonSecondaryText: Color(0xFF4F46E5),
    buttonGhostText: Color(0xFF4F46E5),
    buttonDangerBg: Color(0xFFEF4444),
    buttonDangerText: Color(0xFFFFFFFF),

    // Floating Navigation
    navBg: Color(0xF5111827),
    navSelectedPill: Color(0xFF312E81),
    navSelectedIcon: Color(0xFF818CF8),
    navUnselectedIcon: Color(0xFF94A3B8),
    navDivider: Colors.transparent,
    navShadow: Color(0x4D000000),
    navFab: Color(0xFF4F46E5),
    navFabIcon: Color(0xFFFFFFFF),
    navFabShadow: Color(0x594F46E5),

    // Progress Bars
    progressBudgetSafe: Color(0xFF22C55E),
    progressNearLimit: Color(0xFFF59E0B),
    progressExceeded: Color(0xFFEF4444),
    progressTrack: Color(0xFF2D3A52),

    // Heatmap
    heatmapNoExpense: Color(0xFF172033),
    heatmapLow: Color(0xFF2E5AAC),
    heatmapMedium: Color(0xFF4F46E5),
    heatmapHigh: Color(0xFF7C3AED),
    heatmapVeryHigh: Color(0xFFA855F7),

    // Calendar
    calendarSelectedDate: Color(0xFF4F46E5),
    calendarTodayRing: Color(0xFF818CF8),

    // Financial States (Backwards Compatibility)
    secondary: Color(0xFF818CF8),
    income: Color(0xFF22C55E),
    savings: Color(0xFF10B981),
    expense: Color(0xFFEF4444),
    transfer: Color(0xFF8B5CF6),
    budget: Color(0xFF3B82F6),
    investment: Color(0xFF6366F1),
    neutralStatus: Color(0xFF64748B),

    // Neutrals Scale
    neutral50: Color(0xFFF8FAFC),
    neutral100: Color(0xFFF1F5F9),
    neutral200: Color(0xFFE2E8F0),
    neutral300: Color(0xFFCBD5E1),
    neutral400: Color(0xFF94A3B8),
    neutral500: Color(0xFF64748B),
    neutral600: Color(0xFF475569),
    neutral700: Color(0xFF334155),
    neutral800: Color(0xFF1E293B),
    neutral900: Color(0xFFFFFFFF),
  );

  static const _spacing = SpendlySpacing();

  static final _radius = SpendlyRadius(
    small: BorderRadius.circular(14),
    medium: BorderRadius.circular(16),
    large: BorderRadius.circular(24),
    xlarge: BorderRadius.circular(28),
    xxlarge: BorderRadius.circular(32),
  );

  static const _elevationLight = SpendlyElevation(
    surface0: [],
    surface1: [BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2))],
    surface2: [BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 4))],
    surface3: [BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 8))],
    surface4: [BoxShadow(color: Color(0x2E0F172A), blurRadius: 32, offset: Offset(0, 12))],
  );

  static const _elevationDark = SpendlyElevation(
    surface0: [],
    surface1: [BoxShadow(color: Color(0x2E000000), blurRadius: 8, offset: Offset(0, 2))],
    surface2: [BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 4))],
    surface3: [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
    surface4: [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 12))],
  );

  static const _animation = SpendlyAnimation();
  static const _icons = SpendlyIcons();

  static const List<Color> _sequentialPalette = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
  ];

  static const Map<String, Color> _categoryMap = {
    'food': Color(0xFFF59E0B),
    'groceries': Color(0xFF10B981),
    'travel': Color(0xFF06B6D4),
    'fuel': Color(0xFFF97316),
    'petrol': Color(0xFFF97316),
    'medical': Color(0xFFEF4444),
    'shopping': Color(0xFFEC4899),
    'education': Color(0xFF8B5CF6),
    'entertainment': Color(0xFFA855F7),
    'insurance': Color(0xFF2563EB),
    'insurances': Color(0xFF2563EB),
    'bills': Color(0xFF14B8A6),
    'rent': Color(0xFFF97316),
    'salary': Color(0xFF22C55E),
    'investment': Color(0xFF6366F1),
    'recharges': Color(0xFF06B6D4),
    'gas': Color(0xFFF97316),
    'electricity': Color(0xFF14B8A6),
    'utility': Color(0xFF14B8A6),
    'college': Color(0xFF8B5CF6),
    'others': Color(0xFF64748B),
  };

  static const _chartThemeLight = SpendlyChartTheme(
    grid: Color(0xFFE2E8F0),
    axis: Color(0xFF94A3B8),
    tooltip: Color(0xFF111827),
    legend: Color(0xFF475569),
    label: Color(0xFF475569),
    selected: Color(0xFF4F46E5),
    hovered: Color(0xFF6366F1),
    chartBackground: Colors.transparent,
    sequentialPalette: _sequentialPalette,
    categories: _categoryMap,
    fallbackCategoryColor: Color(0xFF64748B),
  );

  static const _chartThemeDark = SpendlyChartTheme(
    grid: Color(0xFF233044),
    axis: Color(0xFF64748B),
    tooltip: Color(0xFF172033),
    legend: Color(0xFFCBD5E1),
    label: Color(0xFFCBD5E1),
    selected: Color(0xFF4F46E5),
    hovered: Color(0xFF6366F1),
    chartBackground: Colors.transparent,
    sequentialPalette: _sequentialPalette,
    categories: _categoryMap,
    fallbackCategoryColor: Color(0xFF64748B),
  );

  // ====================================================
  // FLUTTER THEMEDATA - LIGHT THEME
  // ====================================================
  static ThemeData get lightTheme {
    final colors = _lightColors;
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colors.primary,
        onPrimary: colors.textInverse,
        primaryContainer: const Color(0xFFEEF2FF),
        onPrimaryContainer: const Color(0xFF312E81),
        secondary: colors.primaryLight,
        onSecondary: colors.textInverse,
        secondaryContainer: const Color(0xFFE0E7FF),
        onSecondaryContainer: const Color(0xFF1E1B4B),
        surface: colors.cardSurface,
        onSurface: colors.textPrimary,
        surfaceContainer: colors.backgroundPrimary,
        surfaceContainerHigh: colors.backgroundSecondary,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.border,
        outlineVariant: colors.outline,
        error: colors.error,
        onError: colors.textInverse,
        errorContainer: colors.errorBackground,
        onErrorContainer: colors.errorDark,
        background: colors.backgroundPrimary,
        onBackground: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.backgroundPrimary,
      extensions: const [
        SpendlyTheme(
          colors: colors,
          spacing: _spacing,
          radius: _radius,
          elevation: _elevationLight,
          animation: _animation,
          icons: _icons,
          charts: _chartThemeLight,
        )
      ],
      cardTheme: CardThemeData(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _radius.large,
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.modalSurface,
        modalBackgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: _radius.large,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.backgroundSecondary,
        selectedColor: const Color(0xFFEEF2FF),
        secondarySelectedColor: colors.primary,
        labelStyle: TextStyle(color: colors.textPrimary),
        secondaryLabelStyle: TextStyle(color: colors.textInverse),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.buttonPrimaryBg,
          foregroundColor: colors.buttonPrimaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: _radius.medium,
          ),
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputNormalBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputNormalBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputFocusedBorder, width: 2),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.inputPlaceholder,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.textSecondary),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.textSecondary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.textTertiary),
      ),
    );
  }

  // ====================================================
  // FLUTTER THEMEDATA - DARK THEME
  // ====================================================
  static ThemeData get darkTheme {
    final colors = _darkColors;
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: colors.textInverse,
        primaryContainer: const Color(0xFF312E81),
        onPrimaryContainer: const Color(0xFFE0E7FF),
        secondary: colors.primaryLight,
        onSecondary: colors.textInverse,
        secondaryContainer: const Color(0xFF1E1B4B),
        onSecondaryContainer: const Color(0xFFC7D2FE),
        surface: colors.cardSurface,
        onSurface: colors.textPrimary,
        surfaceContainer: colors.backgroundPrimary,
        surfaceContainerHigh: colors.backgroundSecondary,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.border,
        outlineVariant: colors.outline,
        error: colors.error,
        onError: colors.textInverse,
        errorContainer: colors.errorDark,
        onErrorContainer: colors.errorBackground,
        background: colors.backgroundPrimary,
        onBackground: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.backgroundPrimary,
      extensions: const [
        SpendlyTheme(
          colors: colors,
          spacing: _spacing,
          radius: _radius,
          elevation: _elevationDark,
          animation: _animation,
          icons: _icons,
          charts: _chartThemeDark,
        )
      ],
      cardTheme: CardThemeData(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _radius.large,
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.modalSurface,
        modalBackgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: _radius.large,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.cardSurface,
        selectedColor: const Color(0xFF312E81),
        secondarySelectedColor: colors.primary,
        labelStyle: TextStyle(color: colors.textPrimary),
        secondaryLabelStyle: TextStyle(color: colors.textInverse),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.buttonPrimaryBg,
          foregroundColor: colors.buttonPrimaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: _radius.medium,
          ),
          textStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputNormalBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputNormalBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radius.small,
          borderSide: BorderSide(color: colors.inputFocusedBorder, width: 2),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.inputPlaceholder,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.textSecondary),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.textSecondary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.textTertiary),
      ),
    );
  }
}
