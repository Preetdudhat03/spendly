import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/providers/apk_download_provider.dart';
import 'package:spendly/core/services/apk_download_service.dart';
import 'package:spendly/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApkDownloadProgress', () {
    test('calculates percentage, MB text, and speed formatted strings correctly', () {
      const progress = ApkDownloadProgress(
        progress: 0.456,
        receivedBytes: 15 * 1024 * 1024,
        totalBytes: 30 * 1024 * 1024,
        speedBytesPerSecond: 2.5 * 1024 * 1024,
      );

      expect(progress.percentageText, '46%');
      expect(progress.receivedMbText, '15.0');
      expect(progress.totalMbText, '30.0');
      expect(progress.speedText, '2.5 MB/s');
    });

    test('formats KB/s speed correctly when below 1 MB/s', () {
      const progress = ApkDownloadProgress(
        progress: 0.1,
        receivedBytes: 500 * 1024,
        totalBytes: 5000 * 1024,
        speedBytesPerSecond: 512 * 1024,
      );

      expect(progress.speedText, '512 KB/s');
    });

    test('handles unknown total bytes gracefully', () {
      const progress = ApkDownloadProgress(
        progress: 0.0,
        receivedBytes: 2 * 1024 * 1024,
        totalBytes: 0,
        speedBytesPerSecond: 0,
      );

      expect(progress.totalMbText, '--');
      expect(progress.percentageText, '0%');
      expect(progress.speedText, '');
    });
  });

  group('ApkAssetSelector with ABI matching', () {
    final assets = [
      {
        'name': 'Spendly-v5.8.0.apk',
        'browser_download_url':
            'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0.apk',
      },
      {
        'name': 'Spendly-v5.8.0-arm64-v8a.apk',
        'browser_download_url':
            'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0-arm64-v8a.apk',
      },
      {
        'name': 'Spendly-v5.8.0-armeabi-v7a.apk',
        'browser_download_url':
            'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0-armeabi-v7a.apk',
      },
      {
        'name': 'Spendly-v5.8.0-x86_64.apk',
        'browser_download_url':
            'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0-x86_64.apk',
      },
    ];

    test('selects arm64-v8a split APK when device ABI is arm64-v8a', () {
      final selected = ApkAssetSelector.selectBestApkUrl(
        assets,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );
      expect(
        selected,
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0-arm64-v8a.apk',
      );
    });

    test('selects armeabi-v7a when arm64-v8a not in list but device supports armeabi-v7a', () {
      final selected = ApkAssetSelector.selectBestApkUrl(
        assets,
        supportedAbis: ['armeabi-v7a'],
      );
      expect(
        selected,
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0-armeabi-v7a.apk',
      );
    });

    test('falls back to universal APK when supportedAbis is not specified or empty', () {
      final selected = ApkAssetSelector.selectBestApkUrl(assets);
      expect(
        selected,
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/Spendly-v5.8.0.apk',
      );
    });
  });

  group('ApkDownloadNotifier State Management', () {
    test('initial state is idle with 0 progress', () {
      final notifier = ApkDownloadNotifier();
      expect(notifier.state.status, ApkDownloadStatus.idle);
      expect(notifier.state.progress, 0.0);
      expect(notifier.state.isDownloading, isFalse);
    });

    test('cancelDownload updates state to canceled', () {
      final notifier = ApkDownloadNotifier();
      notifier.cancelDownload();
      expect(notifier.state.status, ApkDownloadStatus.canceled);
      expect(notifier.state.speedBytesPerSecond, 0.0);
    });

    test('reset restores state to idle', () {
      final notifier = ApkDownloadNotifier();
      notifier.cancelDownload();
      expect(notifier.state.status, ApkDownloadStatus.canceled);

      notifier.reset();
      expect(notifier.state.status, ApkDownloadStatus.idle);
    });

    test('handles untrusted URL rejection with failure state', () async {
      final notifier = ApkDownloadNotifier();
      await notifier.startDownload(
        apkUrl: 'https://malicious-site.com/app.apk',
        version: '5.8.0',
        autoPromptInstall: false,
      );

      expect(notifier.state.status, ApkDownloadStatus.failed);
      expect(notifier.state.errorMessage, contains('Untrusted'));
    });
  });
}
