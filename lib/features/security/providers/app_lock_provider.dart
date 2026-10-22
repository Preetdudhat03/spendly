import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/security/services/app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final int timeoutSeconds;
  final bool isDeviceSupported;
  final bool canCheckBiometrics;
  final List<BiometricType> availableBiometrics;
  final bool isAuthenticating;
  final String? authError;

  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.timeoutSeconds,
    this.isDeviceSupported = false,
    this.canCheckBiometrics = false,
    this.availableBiometrics = const [],
    this.isAuthenticating = false,
    this.authError,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    int? timeoutSeconds,
    bool? isDeviceSupported,
    bool? canCheckBiometrics,
    List<BiometricType>? availableBiometrics,
    bool? isAuthenticating,
    String? authError,
    bool clearAuthError = false,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      authError: clearAuthError ? null : (authError ?? this.authError),
    );
  }

  String get biometricsDescription {
    if (!isDeviceSupported) {
      return 'Not supported on this device';
    }
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID & Screen Lock';
    }
    if (availableBiometrics.contains(BiometricType.fingerprint) ||
        availableBiometrics.contains(BiometricType.strong)) {
      return 'Fingerprint & Screen Lock';
    }
    return 'Biometrics or Device Password/PIN';
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockTimeout = 'app_lock_timeout';

  final AppLockService _service;
  final Ref _ref;
  DateTime? _lastPausedAt;

  AppLockNotifier(this._service, this._ref)
      : super(AppLockState(
          isEnabled: HiveService.settings.get(keyAppLockEnabled, defaultValue: false) as bool,
          isLocked: HiveService.settings.get(keyAppLockEnabled, defaultValue: false) as bool,
          timeoutSeconds: HiveService.settings.get(keyAppLockTimeout, defaultValue: 0) as int,
        )) {
    _init();
  }

  Future<void> _init() async {
    await refreshHardwareStatus();
  }

  Future<void> refreshHardwareStatus() async {
    final isSupported = await _service.isDeviceSupported();
    final canBiometrics = await _service.canCheckBiometrics();
    final biometrics = await _service.getAvailableBiometrics();

    state = state.copyWith(
      isDeviceSupported: isSupported,
      canCheckBiometrics: canBiometrics,
      availableBiometrics: biometrics,
    );
  }

  /// Toggle app lock ON or OFF. Prompts authentication first to protect against unauthorized changes.
  Future<bool> toggleAppLock(bool enable) async {
    await refreshHardwareStatus();

    // Authenticate the user to confirm enabling/disabling
    final reason = enable
        ? 'Confirm your fingerprint, face, or lock screen password to enable App Lock'
        : 'Confirm your fingerprint, face, or lock screen password to disable App Lock';

    final result = await _service.authenticate(localizedReason: reason);

    if (result.success) {
      await HiveService.settings.put(keyAppLockEnabled, enable);
      state = state.copyWith(
        isEnabled: enable,
        isLocked: false,
        clearAuthError: true,
      );
      return true;
    } else {
      state = state.copyWith(
        authError: result.errorMessage ?? 'Authentication required to change App Lock settings.',
      );
      return false;
    }
  }

  /// Update lock timeout in seconds (0 = Immediately, 60 = 1 min, etc.)
  Future<void> setTimeoutSeconds(int seconds) async {
    await HiveService.settings.put(keyAppLockTimeout, seconds);
    state = state.copyWith(timeoutSeconds: seconds);
  }

  /// Manually lock the app immediately.
  void lock() {
    if (!state.isEnabled) return;
    state = state.copyWith(isLocked: true, clearAuthError: true);
  }

  /// Manually unlock the app.
  void unlock() {
    state = state.copyWith(isLocked: false, clearAuthError: true);
  }

  /// Authenticate and unlock. Used on startup or resume from background.
  Future<bool> authenticateAndUnlock() async {
    if (!state.isEnabled || !state.isLocked) return true;
    if (state.isAuthenticating) return false;

    state = state.copyWith(isAuthenticating: true, clearAuthError: true);

    final result = await _service.authenticate(
      localizedReason: 'Unlock Spendly with biometrics or screen lock password',
    );

    if (result.success) {
      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
        clearAuthError: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLocked: true,
        isAuthenticating: false,
        authError: result.errorMessage ?? 'Authentication failed. Tap to retry.',
      );
      return false;
    }
  }

  /// Called when the app lifecycle enters background.
  void onAppPaused() {
    _lastPausedAt = DateTime.now();
  }

  /// Called when the app lifecycle resumes.
  void onAppResumed() {
    final auth = _ref.read(authProvider);
    final isLoggedIn = auth.userId != null;

    if (!state.isEnabled || !isLoggedIn) return;

    if (state.isLocked) {
      // Already locked, prompt auth if not already prompting
      if (!state.isAuthenticating) {
        authenticateAndUnlock();
      }
      return;
    }

    if (_lastPausedAt != null) {
      final elapsedSeconds = DateTime.now().difference(_lastPausedAt!).inSeconds;
      if (elapsedSeconds >= state.timeoutSeconds) {
        state = state.copyWith(isLocked: true, clearAuthError: true);
        authenticateAndUnlock();
      }
    }
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return AppLockNotifier(service, ref);
});
