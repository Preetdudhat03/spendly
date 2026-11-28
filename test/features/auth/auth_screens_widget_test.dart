import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/mock_db_service.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/auth/views/auth_callback_screen.dart';
import 'package:spendly/features/auth/views/login_screen.dart';
import 'package:spendly/features/auth/views/otp_verification_screen.dart';
import 'package:spendly/features/auth/views/register_screen.dart';
import 'package:spendly/features/auth/views/verify_email_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;

  setUp(() async {
    AppConfig.isSupabaseInitialized = false;
    tempDir = await Directory.systemTemp.createTemp('spendly_auth_widgets_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveService.settingsBox);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrap(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dbServiceProvider.overrideWithValue(MockDbService(prefs)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: child,
      ),
    );
  }

  testWidgets('OtpVerificationScreen renders required UI in light and dark themes', (tester) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        wrap(
          const OtpVerificationScreen(
            email: 'dudhatpreet@gmail.com',
            mode: OtpVerificationMode.login,
          ),
          mode: mode,
        ),
      );
      await tester.pump();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(
        find.text("We've sent a verification code to your email address."),
        findsOneWidget,
      );
      expect(find.text('du*****@gmail.com'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('VERIFY OTP'), findsOneWidget);
      expect(find.text('Change Email'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    }
  });

  testWidgets('RegisterScreen password strength and validator stay consistent', (tester) async {
    await tester.pumpWidget(wrap(const RegisterScreen()));
    await tester.pump();

    final passwordField = find.byType(TextFormField).at(2);
    await tester.enterText(passwordField, 'Ab1#');
    await tester.pump();

    expect(find.textContaining('Password Strength: Weak'), findsOneWidget);
    expect(find.textContaining('100%'), findsNothing);

    await tester.enterText(passwordField, 'Spendly#2026');
    await tester.pump();
    expect(find.textContaining('Password Strength: Strong'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('LoginScreen supports both Password and Email OTP toggle', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump();

    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Sign in with Email OTP'), findsOneWidget);

    await tester.ensureVisible(find.text('Sign in with Email OTP'));
    await tester.tap(find.text('Sign in with Email OTP'));
    await tester.pump();

    expect(find.text('SEND OTP CODE'), findsOneWidget);
    expect(find.text('Sign in with Password'), findsOneWidget);
  });

  testWidgets('VerifyEmailScreen renders resend and OTP actions', (tester) async {
    await tester.pumpWidget(wrap(const VerifyEmailScreen()));
    await tester.pump();

    expect(find.text('Check Your Inbox'), findsOneWidget);
    expect(find.text('RESEND VERIFICATION EMAIL'), findsOneWidget);
    expect(find.text('Change Email'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
  });

  testWidgets('AuthCallbackScreen renders actionable error instead of blank screen', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AuthCallbackScreen(
          fallbackError: 'This verification link has expired.',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Verification Issue'), findsOneWidget);
    expect(find.text('This verification link has expired.'), findsOneWidget);
    expect(find.text('BACK TO LOGIN'), findsOneWidget);
  });
}
