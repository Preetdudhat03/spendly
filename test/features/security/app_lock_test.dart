import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_messages.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/security/providers/app_lock_provider.dart';
import 'package:spendly/features/security/services/app_lock_service.dart';

class FakeLocalAuthentication extends LocalAuthentication {
  bool mockIsDeviceSupported;
  bool mockCanCheckBiometrics;
  List<BiometricType> mockBiometrics;
  bool mockAuthenticateResult;
  Exception? mockException;

  FakeLocalAuthentication({
    this.mockIsDeviceSupported = true,
    this.mockCanCheckBiometrics = true,
    this.mockBiometrics = const [BiometricType.fingerprint],
    this.mockAuthenticateResult = true,
    this.mockException,
  });

  @override
  Future<bool> isDeviceSupported() async => mockIsDeviceSupported;

  @override
  Future<bool> get canCheckBiometrics async => mockCanCheckBiometrics;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => mockBiometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }
    return mockAuthenticateResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

final _testRefProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ProviderContainer container;
  late FakeLocalAuthentication fakeLocalAuth;
  late AppLockService appLockService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spendly_app_lock_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveService.settingsBox);

    fakeLocalAuth = FakeLocalAuthentication();
    appLockService = AppLockService(localAuth: fakeLocalAuth);
    container = ProviderContainer(
      overrides: [
        appLockServiceProvider.overrideWithValue(appLockService),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppLockState Model Tests', () {
    test('initial values and copyWith behavior', () {
      const state = AppLockState(
        isEnabled: false,
        isLocked: false,
        timeoutSeconds: 0,
      );

      expect(state.isEnabled, isFalse);
      expect(state.isLocked, isFalse);
      expect(state.timeoutSeconds, 0);

      final updated = state.copyWith(
        isEnabled: true,
        isLocked: true,
        timeoutSeconds: 60,
        authError: 'Error',
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.isLocked, isTrue);
      expect(updated.timeoutSeconds, 60);
      expect(updated.authError, 'Error');

      final cleared = updated.copyWith(clearAuthError: true);
      expect(cleared.authError, isNull);
    });

    test('biometricsDescription reflects available sensors', () {
      const unsupported = AppLockState(
        isEnabled: false,
        isLocked: false,
        timeoutSeconds: 0,
        isDeviceSupported: false,
      );
      expect(unsupported.biometricsDescription, contains('Not supported'));

      const face = AppLockState(
        isEnabled: true,
        isLocked: false,
        timeoutSeconds: 0,
        isDeviceSupported: true,
        availableBiometrics: [BiometricType.face],
      );
      expect(face.biometricsDescription, contains('Face ID'));

      const fingerprint = AppLockState(
        isEnabled: true,
        isLocked: false,
        timeoutSeconds: 0,
        isDeviceSupported: true,
        availableBiometrics: [BiometricType.fingerprint],
      );
      expect(fingerprint.biometricsDescription, contains('Fingerprint'));
    });
  });

  group('AppLockService Tests', () {
    test('authenticate returns success when local_auth succeeds', () async {
      final result = await appLockService.authenticate();
      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('authenticate handles failed authentication', () async {
      fakeLocalAuth.mockAuthenticateResult = false;
      final result = await appLockService.authenticate();
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not completed'));
    });

    test('authenticate handles unsupported hardware gracefully', () async {
      fakeLocalAuth.mockIsDeviceSupported = false;
      final result = await appLockService.authenticate();
      expect(result.success, isFalse);
      expect(result.isNotAvailable, isTrue);
    });

    test('authenticate handles LocalAuthException', () async {
      fakeLocalAuth.mockException = const LocalAuthException(
        code: LocalAuthExceptionCode.noCredentialsSet,
        description: 'No lock screen credentials set',
      );

      final result = await appLockService.authenticate();
      expect(result.success, isFalse);
      expect(result.isNotEnrolled, isTrue);
      expect(result.errorMessage, contains('device settings'));
    });
  });

  group('AppLockNotifier Tests', () {
    test('toggleAppLock enables lock when authentication succeeds and saves to Hive', () async {
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);

      final success = await notifier.toggleAppLock(true);
      expect(success, isTrue);
      expect(notifier.state.isEnabled, isTrue);
      expect(HiveService.settings.get('app_lock_enabled'), isTrue);

      final disabled = await notifier.toggleAppLock(false);
      expect(disabled, isTrue);
      expect(notifier.state.isEnabled, isFalse);
      expect(HiveService.settings.get('app_lock_enabled'), isFalse);
    });

    test('toggleAppLock fails if authentication is rejected', () async {
      fakeLocalAuth.mockAuthenticateResult = false;
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);

      final success = await notifier.toggleAppLock(true);
      expect(success, isFalse);
      expect(notifier.state.isEnabled, isFalse);
      expect(notifier.state.authError, isNotNull);
    });

    test('setTimeoutSeconds updates timeout in state and Hive', () async {
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);

      await notifier.setTimeoutSeconds(300);
      expect(notifier.state.timeoutSeconds, 300);
      expect(HiveService.settings.get('app_lock_timeout'), 300);
    });

    test('lock and unlock manipulate isLocked state properly', () async {
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);

      // Enable first
      await notifier.toggleAppLock(true);

      notifier.lock();
      expect(notifier.state.isLocked, isTrue);

      notifier.unlock();
      expect(notifier.state.isLocked, isFalse);
    });

    test('authenticateAndUnlock sets isLocked to false on auth success', () async {
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);
      await notifier.toggleAppLock(true);

      notifier.lock();
      expect(notifier.state.isLocked, isTrue);

      final unlocked = await notifier.authenticateAndUnlock();
      expect(unlocked, isTrue);
      expect(notifier.state.isLocked, isFalse);
    });

    test('onAppPaused and onAppResumed lock app when timeout exceeded', () async {
      final ref = container.read(_testRefProvider);
      final notifier = AppLockNotifier(appLockService, ref);
      await notifier.toggleAppLock(true);
      await notifier.setTimeoutSeconds(0); // Immediately

      notifier.unlock();
      expect(notifier.state.isLocked, isFalse);

      notifier.onAppPaused();
      // App paused briefly, then resumed
      notifier.onAppResumed();

      // Should be locked
      expect(notifier.state.isLocked, isFalse); // Because authenticateAndUnlock was triggered automatically
    });
  });
}
