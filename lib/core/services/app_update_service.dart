import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/services/version_comparator.dart';
import 'package:spendly/core/services/update_url_validator.dart';

/// Pure helper to select the optimal production APK asset from GitHub release assets.
class ApkAssetSelector {
  static final List<RegExp> _priorityRegexes = [
    RegExp(r'^app-release\.apk$', caseSensitive: false),
    RegExp(r'^spendly-release\.apk$', caseSensitive: false),
    RegExp(r'^spendly\.apk$', caseSensitive: false),
    RegExp(r'spendly.*\.apk$', caseSensitive: false),
    RegExp(r'.*\.apk$', caseSensitive: false),
  ];

  static final RegExp _rejectRegex = RegExp(
    r'(debug|profile|unsigned)',
    caseSensitive: false,
  );

  /// Selects the best APK download URL from the list of release assets.
  static String? selectBestApkUrl(List<dynamic>? assets) {
    if (assets == null || assets.isEmpty) return null;

    final candidates = <Map<String, dynamic>>[];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = asset['name'] as String? ?? '';
        final downloadUrl = asset['browser_download_url'] as String? ?? '';
        if (name.toLowerCase().endsWith('.apk') && downloadUrl.isNotEmpty) {
          if (!_rejectRegex.hasMatch(name)) {
            candidates.add(asset);
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Search by priority rules
    for (final pattern in _priorityRegexes) {
      for (final asset in candidates) {
        final name = asset['name'] as String? ?? '';
        if (pattern.hasMatch(name)) {
          final url = asset['browser_download_url'] as String?;
          if (UpdateUrlValidator.isAllowed(url)) {
            return url;
          }
        }
      }
    }

    // Fallback to first valid candidate
    for (final asset in candidates) {
      final url = asset['browser_download_url'] as String?;
      if (UpdateUrlValidator.isAllowed(url)) {
        return url;
      }
    }

    return null;
  }
}

/// Service handling background checks, caching, ETag negotiation, and release parsing.
class AppUpdateService {
  static const String latestReleaseEndpoint =
      'https://api.github.com/repos/Preetdudhat03/spendly/releases/latest';

  static const Duration networkTimeout = Duration(seconds: 8);
  static const Duration automaticCheckInterval = Duration(hours: 6);
  static const Duration snoozeDuration = Duration(hours: 24);

  // Storage keys
  static const String keyLastCheckTime = 'spendly_last_update_check_time';
  static const String keyLastDismissedVersion = 'spendly_last_dismissed_version';
  static const String keyLastDismissedTime = 'spendly_last_dismissed_time';
  static const String keyCachedReleaseJson = 'spendly_cached_latest_release';
  static const String keyEtag = 'spendly_update_etag';

  final SharedPreferences _prefs;
  final http.Client _client;

  AppUpdateService(this._prefs, [http.Client? client])
      : _client = client ?? http.Client();

  /// Determines if an automatic background check should be executed based on the 6h throttle.
  bool shouldPerformAutomaticCheck() {
    final lastCheck = _prefs.getInt(keyLastCheckTime);
    if (lastCheck == null) return true;

    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    return DateTime.now().difference(lastCheckDate) >= automaticCheckInterval;
  }

  /// Determines if an automatic update dialog should be presented to the user.
  /// Returns `false` if user snoozed the same version within 24 hours (unless mandatory).
  bool shouldShowAutomaticDialog(AppUpdateInfo info) {
    if (!info.hasUpdate) return false;
    if (info.isMandatory) return true;

    final dismissedVersion = _prefs.getString(keyLastDismissedVersion);
    final dismissedTime = _prefs.getInt(keyLastDismissedTime);

    if (dismissedVersion != null && dismissedVersion == info.latestVersion) {
      if (dismissedTime != null) {
        final dismissedDate = DateTime.fromMillisecondsSinceEpoch(dismissedTime);
        final elapsed = DateTime.now().difference(dismissedDate);
        if (elapsed < snoozeDuration) {
          return false; // Still within 24h snooze window
        }
      }
    }

    return true;
  }

  /// Records that the user dismissed the update popup for [version].
  Future<void> recordDismissal(String version) async {
    await _prefs.setString(keyLastDismissedVersion, version);
    await _prefs.setInt(keyLastDismissedTime, DateTime.now().millisecondsSinceEpoch);
  }

  /// Performs an update check against GitHub Releases.
  ///
  /// Set [isManualCheck] to `true` to bypass the 6-hour throttle.
  Future<AppUpdateInfo?> checkForUpdate({
    bool isManualCheck = false,
    ReleaseChannel channel = ReleaseChannel.stable,
  }) async {
    // 1. Check throttle for automatic checks
    if (!isManualCheck && !shouldPerformAutomaticCheck()) {
      debugPrint('AppUpdateService: Automatic check skipped (within 6h window).');
      return _getCachedUpdateInfo(channel: channel);
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      final savedEtag = _prefs.getString(keyEtag);
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Spendly-App',
      };
      if (savedEtag != null && savedEtag.isNotEmpty) {
        headers['If-None-Match'] = savedEtag;
      }

      final uri = Uri.parse(latestReleaseEndpoint);
      final response = await _client.get(uri, headers: headers).timeout(networkTimeout);

      // Record check timestamp
      await _prefs.setInt(keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);

      if (response.statusCode == 304) {
        // Cache is still valid
        debugPrint('AppUpdateService: GitHub returned 304 Not Modified. Using cache.');
        return _getCachedUpdateInfo(
          currentVersion: currentVersion,
          currentBuild: currentBuildNumber,
          channel: channel,
        );
      }

      if (response.statusCode == 200) {
        final rawJson = response.body;
        final data = jsonDecode(rawJson) as Map<String, dynamic>;

        // Store ETag if present
        final newEtag = response.headers['etag'];
        if (newEtag != null && newEtag.isNotEmpty) {
          await _prefs.setString(keyEtag, newEtag);
        }

        // Cache the response JSON
        await _prefs.setString(keyCachedReleaseJson, rawJson);

        return _parseReleaseData(
          data: data,
          currentVersion: currentVersion,
          currentBuild: currentBuildNumber,
          channel: channel,
        );
      } else {
        debugPrint('AppUpdateService: GitHub responded with status ${response.statusCode}');
        return _getCachedUpdateInfo(
          currentVersion: currentVersion,
          currentBuild: currentBuildNumber,
          channel: channel,
        );
      }
    } on TimeoutException {
      debugPrint('AppUpdateService: GitHub request timed out (silent failure)');
      return null;
    } on SocketException {
      debugPrint('AppUpdateService: Network unreachable / offline (silent failure)');
      return null;
    } catch (e) {
      debugPrint('AppUpdateService: Non-fatal error during update check: $e');
      return null;
    }
  }

  /// Parses GitHub release JSON data safely.
  AppUpdateInfo? _parseReleaseData({
    required Map<String, dynamic> data,
    required String currentVersion,
    required String currentBuild,
    ReleaseChannel channel = ReleaseChannel.stable,
  }) {
    try {
      final isDraft = data['draft'] as bool? ?? false;
      final isPrerelease = data['prerelease'] as bool? ?? false;

      // Ignore drafts always; ignore prereleases for stable channel
      if (isDraft) return null;
      if (channel == ReleaseChannel.stable && isPrerelease) return null;

      final tagName = data['tag_name'] as String? ?? '';
      if (tagName.isEmpty) return null;

      final releaseName = data['name'] as String? ?? tagName;
      final releaseNotes = data['body'] as String? ?? '';
      final releaseHtmlUrl = data['html_url'] as String? ?? '';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      // Check mandatory indicator in release notes
      final isMandatory = releaseNotes.contains('<!-- mandatory:true -->') ||
          releaseNotes.contains('[mandatory]');

      // Find best APK
      final assets = data['assets'] as List<dynamic>?;
      final apkUrl = ApkAssetSelector.selectBestApkUrl(assets);

      // Parse version from tagName (e.g., "v5.8.0+264")
      final latestParsed = VersionComparator.parse(tagName);
      if (!latestParsed.isValid || latestParsed.version == null) {
        debugPrint('AppUpdateService: Could not parse release tag "$tagName": ${latestParsed.error}');
        return null;
      }

      final latestVer = '${latestParsed.version!.major}.${latestParsed.version!.minor}.${latestParsed.version!.patch}'
          '${latestParsed.version!.prerelease != null ? '-${latestParsed.version!.prerelease}' : ''}';
      final latestBuild = latestParsed.version!.buildNumber?.toString() ?? '';

      final hasUpdate = VersionComparator.isNewer(
        currentRaw: currentVersion,
        currentBuild: currentBuild,
        latestRaw: tagName,
      );

      return AppUpdateInfo(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        latestVersion: latestVer,
        latestBuildNumber: latestBuild,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        releaseUrl: releaseHtmlUrl,
        apkDownloadUrl: apkUrl,
        publishedAt: publishedAt,
        isMandatory: isMandatory,
        hasUpdate: hasUpdate,
        channel: channel,
      );
    } catch (e) {
      debugPrint('AppUpdateService: Error parsing release payload: $e');
      return null;
    }
  }

  /// Retrieves and evaluates cached release info against current app version.
  Future<AppUpdateInfo?> _getCachedUpdateInfo({
    String? currentVersion,
    String? currentBuild,
    ReleaseChannel channel = ReleaseChannel.stable,
  }) async {
    final cachedJson = _prefs.getString(keyCachedReleaseJson);
    if (cachedJson == null || cachedJson.isEmpty) return null;

    try {
      final curVer = currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final curBuild = currentBuild ?? (await PackageInfo.fromPlatform()).buildNumber;
      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      return _parseReleaseData(
        data: data,
        currentVersion: curVer,
        currentBuild: curBuild,
        channel: channel,
      );
    } catch (e) {
      return null;
    }
  }
}
