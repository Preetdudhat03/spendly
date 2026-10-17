import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/providers/apk_download_provider.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/core/widgets/spendly/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const mockInfo = AppUpdateInfo(
    currentVersion: '5.7.11',
    currentBuildNumber: '263',
    latestVersion: '5.8.0',
    latestBuildNumber: '264',
    releaseName: 'Spendly 5.8.0',
    releaseNotes: '## What is New\n- Feature 1\n- Feature 2',
    releaseUrl: 'https://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
    apkDownloadUrl:
        'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/app-release.apk',
    hasUpdate: true,
  );

  Widget createWidgetUnderTest({
    required AppUpdateInfo info,
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(
          body: AppUpdateDialog(updateInfo: info),
        ),
      ),
    );
  }

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('renders dialog elements properly in Light mode', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(info: mockInfo, isDark: false));
      await tester.pumpAndSettle();

      expect(find.text('New Version Available'), findsOneWidget);
      expect(find.text('v5.7.11 → v5.8.0'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Download APK Update'), findsOneWidget);
      expect(find.text('Remind Me Later'), findsOneWidget);
      expect(find.text('View Full Release on GitHub'), findsOneWidget);
    });

    testWidgets('renders dialog properly in Dark mode', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(info: mockInfo, isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('New Version Available'), findsOneWidget);
      expect(find.text('v5.7.11 → v5.8.0'), findsOneWidget);
    });

    testWidgets('hides Remind Me Later when isMandatory is true', (tester) async {
      final mandatoryInfo = mockInfo.copyWith(isMandatory: true);
      await tester.pumpWidget(createWidgetUnderTest(info: mandatoryInfo));
      await tester.pumpAndSettle();

      expect(find.text('Remind Me Later'), findsNothing);
      expect(find.text('Download APK Update'), findsOneWidget);
    });

    testWidgets('AppUpdateDialog.show displays dialog on screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => AppUpdateDialog.show(context, mockInfo, ref),
                    child: const Text('Trigger Update Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Version Available'), findsNothing);

      await tester.tap(find.text('Trigger Update Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('New Version Available'), findsOneWidget);
      expect(find.text('v5.7.11 → v5.8.0'), findsOneWidget);
    });

    testWidgets('renders Live Downloader progress bar when state is downloading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apkDownloadProvider.overrideWith((ref) {
              final notifier = ApkDownloadNotifier();
              notifier.state = const ApkDownloadState(
                status: ApkDownloadStatus.downloading,
                progress: 0.65,
                receivedBytes: 13 * 1024 * 1024,
                totalBytes: 20 * 1024 * 1024,
                speedBytesPerSecond: 2.1 * 1024 * 1024,
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AppUpdateDialog(updateInfo: mockInfo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downloading Update'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('13.0 MB / 20.0 MB'), findsOneWidget);
      expect(find.text('2.1 MB/s'), findsOneWidget);
      expect(find.text('Cancel Download'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Ready to Install view when download completes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apkDownloadProvider.overrideWith((ref) {
              final notifier = ApkDownloadNotifier();
              notifier.state = const ApkDownloadState(
                status: ApkDownloadStatus.readyToInstall,
                progress: 1.0,
                receivedBytes: 20 * 1024 * 1024,
                totalBytes: 20 * 1024 * 1024,
                downloadedFilePath: '/tmp/spendly_update_5.8.0.apk',
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AppUpdateDialog(updateInfo: mockInfo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Complete'), findsOneWidget);
      expect(find.text('Install Now'), findsOneWidget);
    });

    testWidgets('renders Permission Required state with action buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apkDownloadProvider.overrideWith((ref) {
              final notifier = ApkDownloadNotifier();
              notifier.state = const ApkDownloadState(
                status: ApkDownloadStatus.permissionRequired,
                progress: 1.0,
                downloadedFilePath: '/tmp/spendly_update_5.8.0.apk',
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AppUpdateDialog(updateInfo: mockInfo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.text('Open Settings to Allow'), findsOneWidget);
      expect(find.text('I Granted Permission, Install Now'), findsOneWidget);
    });
  });
}

