import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/services/hive_service.dart';

class SettingsState {
  final bool isDarkMode;
  final String currencySymbol;

  SettingsState({
    required this.isDarkMode,
    required this.currencySymbol,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? currencySymbol,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _keyDarkMode = 'is_dark_mode';
  static const _keyCurrency = 'currency_symbol';

  SettingsNotifier()
      : super(SettingsState(
          isDarkMode: HiveService.settings.get(_keyDarkMode, defaultValue: false) as bool,
          currencySymbol: HiveService.settings.get(_keyCurrency, defaultValue: '₹') as String,
        ));

  void toggleDarkMode(bool isDark) {
    HiveService.settings.put(_keyDarkMode, isDark);
    state = state.copyWith(isDarkMode: isDark);
  }

  void updateCurrency(String symbol) {
    HiveService.settings.put(_keyCurrency, symbol);
    state = state.copyWith(currencySymbol: symbol);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
