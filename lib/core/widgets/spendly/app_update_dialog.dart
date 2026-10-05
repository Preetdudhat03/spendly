import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/providers/app_update_provider.dart';
import 'package:spendly/core/services/update_url_validator.dart';
import 'package:spendly/core/widgets/spendly/release_notes_view.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';

/// Spendly App Update Dialog adhering cleanly to Spendly design tokens.
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
    if (updateState.isDialogVisible || !context.mounted) {
      return;
    }

    ref.read(appUpdateStateProvider.notifier).setDialogVisible(true);

    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: !info.isMandatory,
        builder: (dialogContext) => PopScope(
          canPop: !info.isMandatory,
          child: AppUpdateDialog(updateInfo: info),
        ),
      );
    } finally {
      ref.read(appUpdateStateProvider.notifier).setDialogVisible(false);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final publishedDateStr = updateInfo.publishedAt != null
        ? DateFormat('MMM d, yyyy').format(updateInfo.publishedAt!)
        : null;

    final hasDirectApk = updateInfo.apkDownloadUrl != null &&
        updateInfo.apkDownloadUrl!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
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

            // Action: Update Now
            ElevatedButton(
              onPressed: () {
                _launchUrlSafe(context, updateInfo.preferredDownloadUrl);
              },
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
        ),
      ),
    );
  }
}
