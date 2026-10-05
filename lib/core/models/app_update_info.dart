import 'package:flutter/foundation.dart';

enum AppUpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  failed,
}

enum ReleaseChannel {
  stable,
  beta,
}

@immutable
class AppUpdateInfo {
  final String currentVersion;
  final String currentBuildNumber;
  final String latestVersion;
  final String latestBuildNumber;
  final String releaseName;
  final String releaseNotes;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final DateTime? publishedAt;
  final bool isMandatory;
  final bool hasUpdate;
  final ReleaseChannel channel;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseName,
    required this.releaseNotes,
    required this.releaseUrl,
    this.apkDownloadUrl,
    this.publishedAt,
    this.isMandatory = false,
    required this.hasUpdate,
    this.channel = ReleaseChannel.stable,
  });

  /// User-facing version change summary, e.g. "v5.7.11 → v5.8.0"
  String get versionChangeText {
    final cur = currentVersion.isNotEmpty ? 'v$currentVersion' : 'Current';
    final lat = latestVersion.isNotEmpty ? 'v$latestVersion' : 'Latest';
    return '$cur → $lat';
  }

  /// Preferred download or release location
  String get preferredDownloadUrl => apkDownloadUrl ?? releaseUrl;

  AppUpdateInfo copyWith({
    String? currentVersion,
    String? currentBuildNumber,
    String? latestVersion,
    String? latestBuildNumber,
    String? releaseName,
    String? releaseNotes,
    String? releaseUrl,
    String? apkDownloadUrl,
    DateTime? publishedAt,
    bool? isMandatory,
    bool? hasUpdate,
    ReleaseChannel? channel,
  }) {
    return AppUpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      latestVersion: latestVersion ?? this.latestVersion,
      latestBuildNumber: latestBuildNumber ?? this.latestBuildNumber,
      releaseName: releaseName ?? this.releaseName,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseUrl: releaseUrl ?? this.releaseUrl,
      apkDownloadUrl: apkDownloadUrl ?? this.apkDownloadUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      isMandatory: isMandatory ?? this.isMandatory,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      channel: channel ?? this.channel,
    );
  }

  @override
  String toString() {
    return 'AppUpdateInfo(current: $currentVersion+$currentBuildNumber, latest: $latestVersion+$latestBuildNumber, hasUpdate: $hasUpdate, mandatory: $isMandatory)';
  }
}
