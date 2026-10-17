import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:spendly/core/services/update_url_validator.dart';

class ApkDownloadProgress {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;

  const ApkDownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.speedBytesPerSecond,
  });

  String get receivedMbText => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMbText => totalBytes > 0
      ? (totalBytes / (1024 * 1024)).toStringAsFixed(1)
      : '--';

  String get percentageText => '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

  String get speedText {
    if (speedBytesPerSecond <= 0) return '';
    if (speedBytesPerSecond >= 1024 * 1024) {
      return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }
}

class ApkDownloadService {
  final http.Client _client;
  bool _isCanceled = false;

  ApkDownloadService([http.Client? client]) : _client = client ?? http.Client();

  /// Cancels an in-progress download.
  void cancel() {
    _isCanceled = true;
  }

  /// Downloads the APK file from [downloadUrl] with real-time progress callbacks.
  /// Returns the absolute path of the verified APK file on disk.
  Future<String> downloadApk({
    required String downloadUrl,
    required String version,
    required void Function(ApkDownloadProgress progress) onProgress,
  }) async {
    _isCanceled = false;

    if (!UpdateUrlValidator.isAllowed(downloadUrl)) {
      throw const FormatException('Untrusted or invalid update URL.');
    }

    final uri = Uri.parse(downloadUrl);
    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = 'Spendly-App';
    request.headers['Accept'] = 'application/octet-stream, application/vnd.android.package-archive, */*';

    final http.StreamedResponse response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Server responded with HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;

    // Resolve cache directory for storing the APK
    final tempDir = await getTemporaryDirectory();
    final cleanVersion = version.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    final targetPath = '${tempDir.path}/spendly_update_$cleanVersion.apk';

    // Clean up older update files to save device storage
    try {
      final entries = tempDir.listSync();
      for (final entry in entries) {
        if (entry is File &&
            entry.path.contains('spendly_update_') &&
            entry.path.endsWith('.apk')) {
          try {
            entry.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('ApkDownloadService: Note - error cleaning temp APKs: $e');
    }

    final targetFile = File(targetPath);
    if (targetFile.existsSync()) {
      try {
        targetFile.deleteSync();
      } catch (_) {}
    }

    final sink = targetFile.openWrite();
    int receivedBytes = 0;
    final stopwatch = Stopwatch()..start();
    int lastReportBytes = 0;
    int lastReportTimeMs = 0;
    double speedBytesPerSec = 0.0;

    try {
      await for (final chunk in response.stream) {
        if (_isCanceled) {
          await sink.close();
          if (targetFile.existsSync()) {
            try {
              targetFile.deleteSync();
            } catch (_) {}
          }
          throw Exception('Download canceled by user.');
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        final nowMs = stopwatch.elapsedMilliseconds;
        if (nowMs - lastReportTimeMs >= 250 || receivedBytes == totalBytes) {
          final elapsedSec = (nowMs - lastReportTimeMs) / 1000.0;
          if (elapsedSec > 0) {
            speedBytesPerSec = (receivedBytes - lastReportBytes) / elapsedSec;
          }
          lastReportBytes = receivedBytes;
          lastReportTimeMs = nowMs;

          final progressRatio = totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;

          onProgress(ApkDownloadProgress(
            progress: progressRatio,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            speedBytesPerSecond: speedBytesPerSec,
          ));
        }
      }

      await sink.flush();
      await sink.close();
    } catch (e) {
      try {
        await sink.close();
      } catch (_) {}
      if (targetFile.existsSync()) {
        try {
          targetFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }

    // Verify downloaded file integrity
    if (!targetFile.existsSync()) {
      throw const FileSystemException('Downloaded APK file not found on disk.');
    }

    final actualLength = targetFile.lengthSync();
    if (actualLength == 0) {
      try {
        targetFile.deleteSync();
      } catch (_) {}
      throw const FileSystemException('Downloaded APK file is empty.');
    }

    if (totalBytes > 0 && actualLength != totalBytes) {
      try {
        targetFile.deleteSync();
      } catch (_) {}
      throw FileSystemException(
        'Downloaded APK size ($actualLength bytes) does not match expected size ($totalBytes bytes).',
      );
    }

    return targetPath;
  }
}
