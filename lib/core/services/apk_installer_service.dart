import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel wrapper for APK installation and package management on Android.
class ApkInstallerService {
  static const MethodChannel _channel = MethodChannel('com.family.spendly/app_installer');

  /// Checks whether the app has permission to install unknown apps (Android 8.0+ / API 26+).
  /// Returns `true` on Android < 8.0 or non-Android platforms.
  static Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? canInstall = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return canInstall ?? true;
    } on MissingPluginException {
      debugPrint('ApkInstallerService: MethodChannel not implemented on this platform.');
      return true;
    } catch (e) {
      debugPrint('ApkInstallerService: Error checking install permission: $e');
      return true;
    }
  }

  /// Opens the system settings screen for "Install unknown apps" for Spendly.
  static Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('ApkInstallerService: Error opening install permission settings: $e');
      return false;
    }
  }

  /// Launches the system package installer intent for the downloaded APK file.
  static Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('ApkInstallerService: Error invoking installApk: $e');
      return false;
    }
  }

  /// Queries the device's supported CPU ABIs (e.g. ['arm64-v8a', 'armeabi-v7a']).
  static Future<List<String>> getSupportedAbis() async {
    if (!Platform.isAndroid) return const [];
    try {
      final List<dynamic>? abis = await _channel.invokeMethod<List<dynamic>>('getSupportedAbis');
      if (abis != null) {
        return abis.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('ApkInstallerService: Error fetching supported ABIs: $e');
    }
    return const [];
  }
}
