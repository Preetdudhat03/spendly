import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/models/app_update_info.dart';
import 'package:spendly/core/providers/app_update_provider.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/core/widgets/spendly/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    SharedPreferences.setMockInitialValues({});
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          // ignore: invalid_use_of_visible_for_testing_member
          SharedPreferencesAsyncPlatform.instance == null
              ? null as dynamic
              : null as dynamic,
        ),
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
  });
}
