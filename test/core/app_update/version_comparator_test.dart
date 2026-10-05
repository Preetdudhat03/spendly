import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/version_comparator.dart';

void main() {
  group('VersionComparator Parsing', () {
    test('parses standard semver strings', () {
      final res = VersionComparator.parse('1.5.0');
      expect(res.isValid, isTrue);
      expect(res.version!.major, 1);
      expect(res.version!.minor, 5);
      expect(res.version!.patch, 0);
      expect(res.version!.prerelease, isNull);
      expect(res.version!.buildNumber, isNull);
    });

    test('parses with leading v prefix', () {
      final res = VersionComparator.parse('v1.5.0');
      expect(res.isValid, isTrue);
      expect(res.version!.major, 1);
      expect(res.version!.minor, 5);
      expect(res.version!.patch, 0);
    });

    test('parses with build number in version string', () {
      final res = VersionComparator.parse('v5.7.11+263');
      expect(res.isValid, isTrue);
      expect(res.version!.major, 5);
      expect(res.version!.minor, 7);
      expect(res.version!.patch, 11);
      expect(res.version!.buildNumber, 263);
    });

    test('parses with explicit build number parameter', () {
      final res = VersionComparator.parse('5.7.11', explicitBuildNumber: '263');
      expect(res.isValid, isTrue);
      expect(res.version!.major, 5);
      expect(res.version!.minor, 7);
      expect(res.version!.patch, 11);
      expect(res.version!.buildNumber, 263);
    });

    test('parses pre-release tags', () {
      final res = VersionComparator.parse('v5.8.0-beta.1');
      expect(res.isValid, isTrue);
      expect(res.version!.major, 5);
      expect(res.version!.minor, 8);
      expect(res.version!.patch, 0);
      expect(res.version!.prerelease, 'beta.1');
      expect(res.version!.isPrerelease, isTrue);
    });

    test('gracefully rejects malformed strings with descriptive error', () {
      final res1 = VersionComparator.parse('latest');
      expect(res1.isValid, isFalse);
      expect(res1.error, contains('Invalid semantic version format'));

      final res2 = VersionComparator.parse('');
      expect(res2.isValid, isFalse);
      expect(res2.error, contains('empty or null'));

      final res3 = VersionComparator.parse(null);
      expect(res3.isValid, isFalse);
    });
  });

  group('VersionComparator Precedence & Comparison', () {
    test('1.4.0 < 1.5.0', () {
      expect(
        VersionComparator.isNewer(currentRaw: '1.4.0', latestRaw: '1.5.0'),
        isTrue,
      );
      expect(
        VersionComparator.isNewer(currentRaw: '1.5.0', latestRaw: '1.4.0'),
        isFalse,
      );
    });

    test('1.5.0 == 1.5.0 (isNewer should be false)', () {
      expect(
        VersionComparator.isNewer(currentRaw: '1.5.0', latestRaw: '1.5.0'),
        isFalse,
      );
      expect(
        VersionComparator.isNewer(currentRaw: '1.5.0', latestRaw: 'v1.5.0'),
        isFalse,
      );
    });

    test('2.0.0 > 1.9.9', () {
      expect(
        VersionComparator.isNewer(currentRaw: '1.9.9', latestRaw: '2.0.0'),
        isTrue,
      );
    });

    test('Pre-release evaluation: 5.8.0-beta.1 < 5.8.0-rc.1 < 5.8.0', () {
      // beta.1 is older than rc.1
      expect(
        VersionComparator.isNewer(
          currentRaw: '5.8.0-beta.1',
          latestRaw: '5.8.0-rc.1',
        ),
        isTrue,
      );

      // rc.1 is older than release 5.8.0
      expect(
        VersionComparator.isNewer(
          currentRaw: '5.8.0-rc.1',
          latestRaw: '5.8.0',
        ),
        isTrue,
      );

      // 5.8.0 is NOT older than 5.8.0-rc.1
      expect(
        VersionComparator.isNewer(
          currentRaw: '5.8.0',
          latestRaw: '5.8.0-rc.1',
        ),
        isFalse,
      );
    });

    test('Build numbers compared when semver is identical', () {
      expect(
        VersionComparator.isNewer(
          currentRaw: '5.7.11',
          currentBuild: '263',
          latestRaw: '5.7.11',
          latestBuild: '264',
        ),
        isTrue,
      );

      expect(
        VersionComparator.isNewer(
          currentRaw: '5.7.11+263',
          latestRaw: '5.7.11+263',
        ),
        isFalse,
      );
    });

    test('Major version takes precedence over higher build number', () {
      expect(
        VersionComparator.isNewer(
          currentRaw: '5.7.11+300',
          latestRaw: '5.8.0+100',
        ),
        isTrue,
      );
    });
  });
}
