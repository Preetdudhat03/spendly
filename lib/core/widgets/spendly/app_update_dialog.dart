import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/providers/apk_download_provider.dart';
import 'package:spendly/core/providers/app_update_provider.dart';
import 'package:spendly/core/services/router_service.dart';
import 'package:spendly/core/services/update_url_validator.dart';
import 'package:spendly/core/widgets/spendly/release_notes_view.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';

/// Spendly App Update Dialog with in-app direct downloader,
/// live progress bar, speed tracker, and auto-install prompt.
class AppUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// Displays the update modal dialog safely if not already presented.
  static Future<void> show(
    BuildContext context,
    AppUpdateInfo info,
    WidgetRef ref,
  ) async {
    final updateState = ref.read(appUpdateStateProvider);
    if (updateState.isDialogVisible) {
      return;
    }

    final targetContext = (rootNavigatorKey.currentContext != null &&
            rootNavigatorKey.currentContext!.mounted)
        ? rootNavigatorKey.currentContext!
        : context;

    if (!targetContext.mounted) {
      return;
    }

    ref.read(appUpdateStateProvider.notifier).setDialogVisible(true);

    try {
      await showDialog<void>(
        context: targetContext,
        useRootNavigator: true,
        barrierDismissible: !info.isMandatory,
        builder: (dialogContext) => PopScope(
          canPop: !info.isMandatory,
          child: AppUpdateDialog(updateInfo: info),
        ),
      );
    } finally {
      ref.read(appUpdateStateProvider.notifier).setDialogVisible(false);
      ref.read(apkDownloadProvider.notifier).reset();
    }
  }

  Future<void> _launchUrlSafe(BuildContext context, String urlString) async {
    if (!UpdateUrlValidator.isAllowed(urlString)) {
      if (context.mounted) {
        SpendlyToast.showError(context, 'Invalid or untrusted update URL.');
      }
      return;
    }

    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        SpendlyToast.showError(context, 'Could not open update link.');
      }
    } catch (e) {
      if (context.mounted) {
        SpendlyToast.showError(context, 'Failed to open browser: $e');
      }
    }
  }

  void _onDownloadPressed(BuildContext context, WidgetRef ref, bool hasDirectApk) {
    if (Platform.isAndroid && hasDirectApk && updateInfo.apkDownloadUrl != null) {
      ref.read(apkDownloadProvider.notifier).startDownload(
            apkUrl: updateInfo.apkDownloadUrl!,
            version: updateInfo.latestVersion,
          );
    } else {
      _launchUrlSafe(context, updateInfo.preferredDownloadUrl);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final downloadState = ref.watch(apkDownloadProvider);

    final isDownloadingOrFinished = downloadState.status != ApkDownloadStatus.idle &&
        downloadState.status != ApkDownloadStatus.canceled;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: isDownloadingOrFinished
              ? _buildDownloaderView(context, ref, downloadState, theme, colorScheme, isDark)
              : _buildReleaseNotesView(context, ref, theme, colorScheme, isDark),
        ),
      ),
    );
  }

  /// Initial view showing release info and "Download APK Update" button.
  Widget _buildReleaseNotesView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final publishedDateStr = updateInfo.publishedAt != null
        ? DateFormat('MMM d, yyyy').format(updateInfo.publishedAt!)
        : null;

    final hasDirectApk = updateInfo.apkDownloadUrl != null &&
        updateInfo.apkDownloadUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Badge Icon
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header Title
        Text(
          'New Version Available',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),

        // Release Title & Version Badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              updateInfo.versionChangeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),

        if (publishedDateStr != null) ...[
          const SizedBox(height: 6),
          Text(
            'Released $publishedDateStr',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],

        const SizedBox(height: 16),

        // "What's New" section
        Text(
          "What's New",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Scrollable Release Notes View
        Flexible(
          child: ReleaseNotesView(rawNotes: updateInfo.releaseNotes),
        ),

        const SizedBox(height: 20),

        // Action: Direct Download APK or Open Browser
        ElevatedButton(
          onPressed: () => _onDownloadPressed(context, ref, hasDirectApk),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                hasDirectApk ? 'Download APK Update' : 'Update Now',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),

        // Action: View Release Page on GitHub (if direct APK is present)
        if (hasDirectApk && updateInfo.releaseUrl.isNotEmpty) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              _launchUrlSafe(context, updateInfo.releaseUrl);
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
            ),
            child: const Text(
              'View Full Release on GitHub',
              style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
        ],

        // Action: Remind Me Later (omitted if mandatory)
        if (!updateInfo.isMandatory) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () async {
              await ref
                  .read(appUpdateStateProvider.notifier)
                  .dismissUpdate(updateInfo.latestVersion);
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white60 : Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Remind Me Later',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  /// Live Downloader view with progress bar, download speed, and auto-install states.
  Widget _buildDownloaderView(
    BuildContext context,
    WidgetRef ref,
    ApkDownloadState downloadState,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    switch (downloadState.status) {
      case ApkDownloadStatus.downloading:
        return _buildActiveDownloadState(context, ref, downloadState, theme, colorScheme, isDark);

      case ApkDownloadStatus.verifying:
        return _buildVerifyingState(theme, colorScheme, isDark);

      case ApkDownloadStatus.readyToInstall:
      case ApkDownloadStatus.installing:
        return _buildInstallReadyState(context, ref, downloadState, theme, colorScheme, isDark);

      case ApkDownloadStatus.permissionRequired:
        return _buildPermissionRequiredState(context, ref, downloadState, theme, colorScheme, isDark);

      case ApkDownloadStatus.failed:
        return _buildFailedState(context, ref, downloadState, theme, colorScheme, isDark);

      case ApkDownloadStatus.idle:
      case ApkDownloadStatus.canceled:
        return const SizedBox.shrink();
    }
  }

  /// Active Downloading state with live progress bar and speed
  Widget _buildActiveDownloadState(
    BuildContext context,
    WidgetRef ref,
    ApkDownloadState downloadState,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download_rounded,
              color: colorScheme.primary,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Downloading Update',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Spendly v${updateInfo.latestVersion}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),

        // Live Animated Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: downloadState.totalBytes > 0 ? downloadState.progress : null,
            minHeight: 10,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 10),

        // Progress Percent & Size Metrics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              downloadState.percentageText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.primary,
              ),
            ),
            Text(
              '${downloadState.receivedMbText} MB / ${downloadState.totalMbText} MB',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Download Speed Indicator
        if (downloadState.speedText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 4),
              Text(
                downloadState.speedText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Cancel Button
        OutlinedButton(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).cancelDownload();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel Download', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  /// Verifying Package state
  Widget _buildVerifyingState(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Verifying Package',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verifying APK integrity before install...',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Download complete / Ready to Install state
  Widget _buildInstallReadyState(
    BuildContext context,
    WidgetRef ref,
    ApkDownloadState downloadState,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isInstalling = downloadState.status == ApkDownloadStatus.installing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Download Complete',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isInstalling
              ? 'Opening package installer...'
              : 'APK downloaded and verified. Tap below to install.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),

        if (downloadState.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              downloadState.errorMessage!,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).installDownloadedApk();
          },
          icon: const Icon(Icons.system_update_rounded, size: 18),
          label: const Text(
            'Install Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),

        if (!updateInfo.isMandatory) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }

  /// Unknown Sources permission required state (Android 8.0+)
  Widget _buildPermissionRequiredState(
    BuildContext context,
    WidgetRef ref,
    ApkDownloadState downloadState,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.amber,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Permission Required',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To install updates, Android requires permission to install unknown apps from Spendly.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Action: Open Android settings
        ElevatedButton.icon(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).openSettingsForPermission();
          },
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: const Text('Open Settings to Allow'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),

        // Action: Retry install after granting permission
        OutlinedButton(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).checkPermissionAndInstall();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('I Granted Permission, Install Now'),
        ),
      ],
    );
  }

  /// Download failed state with retry and browser fallback
  Widget _buildFailedState(
    BuildContext context,
    WidgetRef ref,
    ApkDownloadState downloadState,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Download Failed',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          downloadState.errorMessage ?? 'An error occurred while downloading the update.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.red.shade400,
          ),
        ),
        const SizedBox(height: 20),

        // Action: Retry Download
        ElevatedButton.icon(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).startDownload(
                  apkUrl: updateInfo.apkDownloadUrl ?? updateInfo.preferredDownloadUrl,
                  version: updateInfo.latestVersion,
                );
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),

        // Action: Fallback to Browser
        OutlinedButton(
          onPressed: () {
            _launchUrlSafe(context, updateInfo.preferredDownloadUrl);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Download via Browser Instead'),
        ),
        const SizedBox(height: 4),

        // Action: Back to notes
        TextButton(
          onPressed: () {
            ref.read(apkDownloadProvider.notifier).reset();
          },
          child: const Text('Back to Release Notes'),
        ),
      ],
    );
  }
}
