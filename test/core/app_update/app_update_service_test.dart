import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Spendly',
      packageName: 'com.spendly.app',
      version: '5.7.11',
      buildNumber: '263',
      buildSignature: '',
    );
  });

  group('ApkAssetSelector', () {
    test('prefers app-release.apk over generic names', () {
      final assets = [
        {
          'name': 'spendly-debug.apk',
          'browser_download_url':
              'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/spendly-debug.apk',
        },
        {
          'name': 'spendly-release.apk',
          'browser_download_url':
              'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/spendly-release.apk',
        },
        {
          'name': 'app-release.apk',
          'browser_download_url':
              'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/app-release.apk',
        },
      ];

      final selected = ApkAssetSelector.selectBestApkUrl(assets);
      expect(
        selected,
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/app-release.apk',
      );
    });

    test('rejects debug, profile and unsigned APKs', () {
      final assets = [
        {
          'name': 'app-debug.apk',
          'browser_download_url':
              'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/app-debug.apk',
        },
        {
          'name': 'spendly-profile.apk',
          'browser_download_url':
              'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/spendly-profile.apk',
        },
      ];

      final selected = ApkAssetSelector.selectBestApkUrl(assets);
      expect(selected, isNull);
    });
  });

  group('AppUpdateService Caching & Snooze', () {
    test('6-hour throttle for automatic check', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppUpdateService(prefs);

      // Initially no check has run
      expect(service.shouldPerformAutomaticCheck(), isTrue);

      // After check runs now
      await prefs.setInt(
        AppUpdateService.keyLastCheckTime,
        DateTime.now().millisecondsSinceEpoch,
      );
      expect(service.shouldPerformAutomaticCheck(), isFalse);

      // After 7 hours
      final sevenHoursAgo =
          DateTime.now().subtract(const Duration(hours: 7)).millisecondsSinceEpoch;
      await prefs.setInt(AppUpdateService.keyLastCheckTime, sevenHoursAgo);
      expect(service.shouldPerformAutomaticCheck(), isTrue);
    });

    test('24-hour snooze suppression on dismissal', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppUpdateService(prefs);

      const info = AppUpdateInfo(
        currentVersion: '5.7.11',
        currentBuildNumber: '263',
        latestVersion: '5.8.0',
        latestBuildNumber: '264',
        releaseName: 'Spendly 5.8.0',
        releaseNotes: 'What is new',
        releaseUrl: 'https://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
        hasUpdate: true,
      );

      // Should show before dismissal
      expect(service.shouldShowAutomaticDialog(info), isTrue);

      // Dismiss version 5.8.0
      await service.recordDismissal('5.8.0');

      // Now it should be suppressed within 24 hours
      expect(service.shouldShowAutomaticDialog(info), isFalse);

      // If newer version arrives, it should show immediately
      final newerInfo = info.copyWith(latestVersion: '5.8.1');
      expect(service.shouldShowAutomaticDialog(newerInfo), isTrue);
    });

    test('manual check (isManualCheck: true) bypasses the 6-hour throttle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // Mark as checked 5 minutes ago
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await prefs.setInt(AppUpdateService.keyLastCheckTime, fiveMinAgo);

      var networkCallCount = 0;
      final mockClient = MockClient((request) async {
        networkCallCount++;
        return http.Response(
          jsonEncode({
            'tag_name': 'v5.8.0',
            'draft': false,
            'prerelease': false,
            'html_url': 'https://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
          }),
          200,
        );
      });

      final service = AppUpdateService(prefs, mockClient);

      // Automatic check should be throttled
      final autoResult = await service.checkForUpdate(isManualCheck: false);
      expect(networkCallCount, 0, reason: 'Automatic check within 6h should NOT hit network');
      expect(autoResult, isNull);

      // Manual check MUST bypass throttle and hit network
      final manualResult = await service.checkForUpdate(isManualCheck: true);
      expect(networkCallCount, 1, reason: 'Manual check MUST hit network');
      expect(manualResult, isNotNull);
      expect(manualResult!.latestVersion, '5.8.0');
    });
  });

  group('AppUpdateService API Request & Response Parsing', () {
    test('parses HTTP 200 release with update available', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'tag_name': 'v5.8.0',
          'name': 'Spendly 5.8.0 - New Analytics',
          'body': '## What is New\n- Faster sync\n- Export to CSV',
          'html_url': 'https://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
          'draft': false,
          'prerelease': false,
          'published_at': '2026-10-05T12:00:00Z',
          'assets': [
            {
              'name': 'spendly-release.apk',
              'browser_download_url':
                  'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/spendly-release.apk',
            }
          ],
        });
        return http.Response(
          body,
          200,
          headers: {'etag': 'W/"test-etag-123"'},
        );
      });

      final service = AppUpdateService(prefs, mockClient);
      final updateInfo = await service.checkForUpdate(isManualCheck: true);

      expect(updateInfo, isNotNull);
      expect(updateInfo!.hasUpdate, isTrue);
      expect(updateInfo.latestVersion, '5.8.0');
      expect(updateInfo.releaseName, 'Spendly 5.8.0 - New Analytics');
      expect(
        updateInfo.apkDownloadUrl,
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/spendly-release.apk',
      );
      expect(prefs.getString(AppUpdateService.keyEtag), 'W/"test-etag-123"');
    });

    test('ignores drafts and prereleases for stable channel', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'tag_name': 'v5.9.0-beta.1',
          'name': 'Spendly 5.9.0 Beta',
          'body': 'Beta release',
          'html_url': 'https://github.com/Preetdudhat03/spendly/releases/tag/v5.9.0-beta.1',
          'draft': false,
          'prerelease': true,
        });
        return http.Response(body, 200);
      });

      final service = AppUpdateService(prefs, mockClient);
      final updateInfo = await service.checkForUpdate(
        isManualCheck: true,
        channel: ReleaseChannel.stable,
      );

      expect(updateInfo, isNull);
    });

    test('handles network failure silently without throwing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final service = AppUpdateService(prefs, mockClient);
      final updateInfo = await service.checkForUpdate(isManualCheck: true);

      expect(updateInfo, isNull);
    });
  });
}
