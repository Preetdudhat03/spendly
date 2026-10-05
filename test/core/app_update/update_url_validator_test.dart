import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/update_url_validator.dart';

void main() {
  group('UpdateUrlValidator', () {
    test('allows trusted GitHub release page URL', () {
      expect(
        UpdateUrlValidator.isAllowed(
          'https://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
        ),
        isTrue,
      );
    });

    test('allows trusted GitHub release APK asset URL', () {
      expect(
        UpdateUrlValidator.isAllowed(
          'https://github.com/Preetdudhat03/spendly/releases/download/v5.8.0/app-release.apk',
        ),
        isTrue,
      );
    });

    test('allows trusted GitHub objects CDN / AWS S3 asset URL', () {
      expect(
        UpdateUrlValidator.isAllowed(
          'https://objects.githubusercontent.com/github-production-release-asset-2e65be/12345/app-release.apk',
        ),
        isTrue,
      );
    });

    test('rejects insecure HTTP URLs', () {
      expect(
        UpdateUrlValidator.isAllowed(
          'http://github.com/Preetdudhat03/spendly/releases/tag/v5.8.0',
        ),
        isFalse,
      );
    });

    test('rejects foreign github repository URLs', () {
      expect(
        UpdateUrlValidator.isAllowed(
          'https://github.com/maliciousUser/maliciousRepo/releases/tag/v5.8.0',
        ),
        isFalse,
      );
    });

    test('rejects untrusted third-party hosts and scripts', () {
      expect(
        UpdateUrlValidator.isAllowed('https://malicious-site.com/spendly.apk'),
        isFalse,
      );
      expect(
        UpdateUrlValidator.isAllowed('javascript:alert(1)'),
        isFalse,
      );
      expect(
        UpdateUrlValidator.isAllowed(''),
        isFalse,
      );
      expect(
        UpdateUrlValidator.isAllowed(null),
        isFalse,
      );
    });
  });
}
