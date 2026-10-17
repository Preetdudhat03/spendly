import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/services/apk_download_service.dart';
import 'package:spendly/core/services/apk_installer_service.dart';

enum ApkDownloadStatus {
  idle,
  downloading,
  verifying,
  readyToInstall,
  installing,
  permissionRequired,
  failed,
  canceled,
}

@immutable
class ApkDownloadState {
  final ApkDownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;
  final String? downloadedFilePath;
  final String? errorMessage;
  final String? targetVersion;

  const ApkDownloadState({
    this.status = ApkDownloadStatus.idle,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSecond = 0.0,
    this.downloadedFilePath,
    this.errorMessage,
    this.targetVersion,
  });

  bool get isDownloading => status == ApkDownloadStatus.downloading;
  bool get isVerifying => status == ApkDownloadStatus.verifying;
  bool get isInstalling => status == ApkDownloadStatus.installing;
  bool get isReadyToInstall => status == ApkDownloadStatus.readyToInstall;
  bool get isPermissionRequired => status == ApkDownloadStatus.permissionRequired;
  bool get hasFailed => status == ApkDownloadStatus.failed;
  bool get isCompleted => status == ApkDownloadStatus.readyToInstall || status == ApkDownloadStatus.installing;

  String get receivedMbText => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMbText => totalBytes > 0
      ? (totalBytes / (1024 * 1024)).toStringAsFixed(1)
      : '--';

  String get percentageText => '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

  String get speedText {
    if (speedBytesPerSecond <= 0) return '';
    if (speedBytesPerSecond >= 1024 * 1024) {
      return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }

  ApkDownloadState copyWith({
    ApkDownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    String? downloadedFilePath,
    String? errorMessage,
    String? targetVersion,
  }) {
    return ApkDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage,
      targetVersion: targetVersion ?? this.targetVersion,
    );
  }
}

class ApkDownloadNotifier extends StateNotifier<ApkDownloadState> {
  ApkDownloadService _downloadService;

  ApkDownloadNotifier([ApkDownloadService? downloadService])
      : _downloadService = downloadService ?? ApkDownloadService(),
        super(const ApkDownloadState());

  /// Starts downloading the APK from [apkUrl].
  /// When download completes, automatically verifies the file and prompts for installation.
  Future<void> startDownload({
    required String apkUrl,
    required String version,
    bool autoPromptInstall = true,
  }) async {
    // If already downloading the same version, ignore duplicate tap
    if (state.isDownloading && state.targetVersion == version) {
      return;
    }

    _downloadService = ApkDownloadService();

    state = ApkDownloadState(
      status: ApkDownloadStatus.downloading,
      progress: 0.0,
      receivedBytes: 0,
      totalBytes: 0,
      speedBytesPerSecond: 0.0,
      targetVersion: version,
    );

    try {
      final filePath = await _downloadService.downloadApk(
        downloadUrl: apkUrl,
        version: version,
        onProgress: (progressData) {
          state = state.copyWith(
            status: ApkDownloadStatus.downloading,
            progress: progressData.progress,
            receivedBytes: progressData.receivedBytes,
            totalBytes: progressData.totalBytes,
            speedBytesPerSecond: progressData.speedBytesPerSecond,
          );
        },
      );

      // Verifying state
      state = state.copyWith(
        status: ApkDownloadStatus.verifying,
        progress: 1.0,
        downloadedFilePath: filePath,
      );

      // Short delay for verification transition UI feedback
      await Future<void>.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        status: ApkDownloadStatus.readyToInstall,
        downloadedFilePath: filePath,
      );

      // Auto-trigger package installer prompt
      if (autoPromptInstall) {
        await installDownloadedApk();
      }
    } catch (e) {
      if (state.status == ApkDownloadStatus.canceled) {
        return;
      }
      state = state.copyWith(
        status: ApkDownloadStatus.failed,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }

  /// Cancels the ongoing download.
  void cancelDownload() {
    _downloadService.cancel();
    state = state.copyWith(
      status: ApkDownloadStatus.canceled,
      speedBytesPerSecond: 0.0,
    );
  }

  /// Prompts the Android OS package installer to install the downloaded APK.
  Future<bool> installDownloadedApk() async {
    final path = state.downloadedFilePath;
    if (path == null || path.isEmpty) {
      state = state.copyWith(
        status: ApkDownloadStatus.failed,
        errorMessage: 'APK file not found. Please re-download.',
      );
      return false;
    }

    // Check unknown sources install permission on Android 8.0+
    final canInstall = await ApkInstallerService.canRequestPackageInstalls();
    if (!canInstall) {
      state = state.copyWith(
        status: ApkDownloadStatus.permissionRequired,
      );
      return false;
    }

    state = state.copyWith(status: ApkDownloadStatus.installing);

    final launched = await ApkInstallerService.installApk(path);
    if (!launched) {
      state = state.copyWith(
        status: ApkDownloadStatus.readyToInstall,
        errorMessage: 'Unable to open package installer. Tap "Install Now" to retry.',
      );
      return false;
    }

    return true;
  }

  /// Directs user to Android settings to grant unknown apps installation permission.
  Future<void> openSettingsForPermission() async {
    await ApkInstallerService.openInstallPermissionSettings();
  }

  /// Checks if permission was granted after returning from settings, and if so, launches install.
  Future<void> checkPermissionAndInstall() async {
    final canInstall = await ApkInstallerService.canRequestPackageInstalls();
    if (canInstall) {
      await installDownloadedApk();
    } else {
      state = state.copyWith(
        status: ApkDownloadStatus.permissionRequired,
        errorMessage: 'Install permission not yet granted. Please allow Spendly in Settings.',
      );
    }
  }

  /// Resets state back to idle.
  void reset() {
    _downloadService.cancel();
    state = const ApkDownloadState();
  }
}

/// Riverpod provider for APK direct download management
final apkDownloadProvider =
    StateNotifierProvider<ApkDownloadNotifier, ApkDownloadState>((ref) {
  return ApkDownloadNotifier();
});
