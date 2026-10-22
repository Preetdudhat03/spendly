import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final bool isNotEnrolled;
  final bool isNotAvailable;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.isNotEnrolled = false,
    this.isNotAvailable = false,
  });

  const AuthResult.success() : this(success: true);
  const AuthResult.failure([String? message]) : this(success: false, errorMessage: message);
}

class AppLockService {
  final LocalAuthentication _localAuth;

  AppLockService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Check if the device hardware supports biometrics or device credentials.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('[AppLockService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Check if biometric sensors are available and enrolled.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[AppLockService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Get list of available enrolled biometrics (e.g. fingerprint, face, weak, strong).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[AppLockService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Authenticate using biometrics or device lock screen credentials (PIN, pattern, password).
  ///
  /// Setting `biometricOnly: false` allows Android & iOS to automatically
  /// fall back to device screen lock credentials if biometric authentication
  /// is not enrolled or user selects lock screen password/PIN.
  Future<AuthResult> authenticate({
    String localizedReason = 'Authenticate to unlock Spendly',
  }) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return const AuthResult(
          success: false,
          errorMessage: 'Device authentication is not supported on this device.',
          isNotAvailable: true,
        );
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        return const AuthResult.success();
      } else {
        return const AuthResult.failure('Authentication was not completed.');
      }
    } on PlatformException catch (e) {
      debugPrint('[AppLockService] PlatformException: ${e.code} - ${e.message}');
      String message = 'Authentication failed. Please try again.';
      bool notEnrolled = false;
      bool notAvailable = false;

      switch (e.code) {
        case 'NotAvailable':
          message = 'Biometrics or lock screen password is not available.';
          notAvailable = true;
          break;
        case 'NotEnrolled':
          message = 'No lock screen password, PIN, or biometric enrolled on this device. Please set up a screen lock in device settings.';
          notEnrolled = true;
          break;
        case 'LockedOut':
          message = 'Too many failed attempts. Device is temporarily locked.';
          break;
        case 'PermanentlyLockedOut':
          message = 'Too many failed attempts. Unlock using your device password.';
          break;
        case 'UserCancel':
        case 'SystemCancel':
          message = 'Authentication canceled.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
          break;
      }

      return AuthResult(
        success: false,
        errorMessage: message,
        isNotEnrolled: notEnrolled,
        isNotAvailable: notAvailable,
      );
    } catch (e) {
      debugPrint('[AppLockService] Unexpected error: $e');
      return AuthResult.failure('Unexpected authentication error: $e');
    }
  }

  /// Cancels any ongoing authentication prompt.
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      debugPrint('[AppLockService] stopAuthentication error: $e');
    }
  }
}
