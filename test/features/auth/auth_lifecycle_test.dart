import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/constants/auth_constants.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/auth_deep_link_service.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/mock_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    AppConfig.isSupabaseInitialized = false;
    tempDir = await Directory.systemTemp.createTemp('spendly_auth_lifecycle_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveService.settingsBox);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dbServiceProvider.overrideWithValue(MockDbService(prefs)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AuthConstants.maskEmail', () {
    test('masks standard and short emails safely', () {
      expect(AuthConstants.maskEmail('dudhatpreet@gmail.com'), 'du*****@gmail.com');
      expect(AuthConstants.maskEmail('ab@gmail.com'), 'a***@gmail.com');
    });
  });

  group('AuthNotifier lifecycle & state transitions', () {
    test('resolves from initializing to unauthenticated without hanging', () async {
      final notifier = container.read(authProvider.notifier);
      expect(notifier, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final state = container.read(authProvider);
      expect(state.isInitializing, isFalse);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('signup transitions to verificationPending and does not authenticate', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final ok = await container
          .read(authProvider.notifier)
          .signUp('preet@example.com', 'Spendly#2026', 'Preet');
      expect(ok, isTrue);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.verificationPending);
      expect(state.userId, isNull);
      expect(state.pendingEmail, 'preet@example.com');
      expect(state.verificationPurpose, VerificationPurpose.signup);
    });

    test('signup rejects invalid email and weak password', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final badEmail = await container
          .read(authProvider.notifier)
          .signUp('not-an-email', 'Spendly#2026', 'Preet');
      expect(badEmail, isFalse);
      expect(container.read(authProvider).status, AuthStatus.error);

      final badPass = await container
          .read(authProvider.notifier)
          .signUp('preet@example.com', '1234', 'Preet');
      expect(badPass, isFalse);
      expect(container.read(authProvider).status, AuthStatus.error);
    });

    test('resendSignupVerification enforces cooldown without duplicate signup', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await container
          .read(authProvider.notifier)
          .signUp('preet@example.com', 'Spendly#2026', 'Preet');
      final secondAttempt = await container
          .read(authProvider.notifier)
          .resendSignupVerification('preet@example.com');
      expect(secondAttempt, isFalse);
      expect(container.read(authProvider).error, contains('wait'));
    });

    test('sendEmailOtp sets verificationPending for otpLogin and rejects invalid token', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final sent = await container
          .read(authProvider.notifier)
          .sendEmailOtp('preet@example.com');
      expect(sent, isTrue);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.verificationPending);
      expect(state.verificationPurpose, VerificationPurpose.otpLogin);

      final verifiedBad = await container
          .read(authProvider.notifier)
          .verifyEmailOtp(email: 'preet@example.com', token: '12');
      expect(verifiedBad, isFalse);
      expect(container.read(authProvider).error, contains('6-digit'));
    });

    test('updateEmail sets pendingEmail without overwriting current email or UUID', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final db = container.read(dbServiceProvider);
      await db.signUp(
        email: 'user1@example.com',
        password: 'Spendly#2026',
        displayName: 'User One',
      );
      final signedIn = await container
          .read(authProvider.notifier)
          .signIn('user1@example.com', 'Spendly#2026');
      expect(signedIn, isTrue);

      final originalUserId = container.read(authProvider).userId;
      expect(originalUserId, isNotNull);
      expect(container.read(authProvider).email, 'user1@example.com');

      final requested = await container
          .read(authProvider.notifier)
          .updateEmail('newemail@example.com');
      expect(requested, isTrue);

      final afterRequest = container.read(authProvider);
      expect(afterRequest.userId, originalUserId);
      expect(afterRequest.email, 'user1@example.com');
      expect(afterRequest.pendingEmail, 'newemail@example.com');
      expect(afterRequest.verificationPurpose, VerificationPurpose.emailChange);

      container.read(authProvider.notifier).cancelPendingEmailChange();
      final afterCancel = container.read(authProvider);
      expect(afterCancel.pendingEmail, isNull);
      expect(afterCancel.email, 'user1@example.com');
      expect(afterCancel.userId, originalUserId);
    });

    test('handleAuthCallback with error sets AuthStatus.error and never hangs', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final errorUri = Uri.parse(
        'spendly://auth-callback?error=access_denied&error_code=otp_expired',
      );
      final parsed = AuthDeepLinkService.parseCallbackUri(errorUri);
      await container.read(authProvider.notifier).handleAuthCallback(parsed);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('expired'));
    });
  });
}
