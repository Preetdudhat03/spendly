import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/app_update_service.dart';

@immutable
class AppUpdateState {
  final AppUpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final bool isDialogVisible;
  final bool isChecking;
  final String? errorMessage;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.updateInfo,
    this.isDialogVisible = false,
    this.isChecking = false,
    this.errorMessage,
  });

  bool get hasUpdate => updateInfo?.hasUpdate == true;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? updateInfo,
    bool? isDialogVisible,
    bool? isChecking,
    String? errorMessage,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      isDialogVisible: isDialogVisible ?? this.isDialogVisible,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: errorMessage,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final AppUpdateService _service;

  AppUpdateNotifier(this._service) : super(const AppUpdateState());

  /// Sets whether the update popup dialog is currently open in the UI.
  void setDialogVisible(bool visible) {
    state = state.copyWith(isDialogVisible: visible);
  }

  /// Records that the user dismissed the update for [version].
  Future<void> dismissUpdate(String version) async {
    await _service.recordDismissal(version);
    setDialogVisible(false);
  }

  /// Checks for updates.
  ///
  /// Set [isManual] to true for user-initiated checks (from Profile screen).
  Future<AppUpdateInfo?> checkForUpdate({
    bool isManual = false,
    ReleaseChannel channel = ReleaseChannel.stable,
  }) async {
    // Prevent duplicate simultaneous checks
    if (state.isChecking) {
      debugPrint('AppUpdateNotifier: Check already in progress. Ignoring duplicate call.');
      return state.updateInfo;
    }

    state = state.copyWith(
      status: AppUpdateStatus.checking,
      isChecking: true,
      errorMessage: null,
    );

    try {
      final info = await _service.checkForUpdate(
        isManualCheck: isManual,
        channel: channel,
      );

      if (info == null) {
        // Silent failure or offline
        state = state.copyWith(
          status: isManual ? AppUpdateStatus.failed : AppUpdateStatus.idle,
          isChecking: false,
          errorMessage: isManual ? 'Unable to reach update server.' : null,
        );
        return null;
      }

      if (info.hasUpdate) {
        state = state.copyWith(
          status: AppUpdateStatus.updateAvailable,
          updateInfo: info,
          isChecking: false,
        );
      } else {
        state = state.copyWith(
          status: AppUpdateStatus.upToDate,
          updateInfo: info,
          isChecking: false,
        );
      }

      return info;
    } catch (e) {
      state = state.copyWith(
        status: isManual ? AppUpdateStatus.failed : AppUpdateStatus.idle,
        isChecking: false,
        errorMessage: isManual ? e.toString() : null,
      );
      return null;
    }
  }

  /// Evaluates whether the automatic update dialog should be shown for the given [info].
  bool shouldShowAutomaticDialog(AppUpdateInfo info) {
    return _service.shouldShowAutomaticDialog(info);
  }
}

/// Provider for the AppUpdateService
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppUpdateService(prefs);
});

/// StateNotifierProvider for the update controller
final appUpdateStateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return AppUpdateNotifier(service);
});
