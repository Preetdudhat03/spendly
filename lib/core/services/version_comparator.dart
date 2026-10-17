import 'package:flutter/foundation.dart';

/// Representation of a parsed semantic version with build and pre-release identifiers.
@immutable
class ParsedVersion implements Comparable<ParsedVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? prerelease;
  final int? buildNumber;
  final String raw;

  const ParsedVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease,
    this.buildNumber,
    required this.raw,
  });

  bool get isPrerelease => prerelease != null && prerelease!.isNotEmpty;

  @override
  int compareTo(ParsedVersion other) {
    // 1. Compare Major
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    // 2. Compare Minor
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    // 3. Compare Patch
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }

    // 4. Compare Pre-release
    // A normal version (no pre-release) has higher precedence than a pre-release version:
    // e.g. 5.8.0 > 5.8.0-rc.1 > 5.8.0-beta.1
    if (isPrerelease && !other.isPrerelease) {
      return -1;
    }
    if (!isPrerelease && other.isPrerelease) {
      return 1;
    }
    if (isPrerelease && other.isPrerelease) {
      final preComp = _comparePrerelease(prerelease!, other.prerelease!);
      if (preComp != 0) return preComp;
    }

    // 5. Compare Build Number (only if semver + prerelease are identical)
    final thisBuild = buildNumber ?? 0;
    final otherBuild = other.buildNumber ?? 0;
    if (thisBuild != otherBuild) {
      return thisBuild.compareTo(otherBuild);
    }

    return 0;
  }

  static int _comparePrerelease(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final minLen = aParts.length < bParts.length ? aParts.length : bParts.length;

    for (int i = 0; i < minLen; i++) {
      final aPart = aParts[i];
      final bPart = bParts[i];

      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);

      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else if (aNum != null && bNum == null) {
        // Numeric identifiers have lower precedence than string identifiers
        return -1;
      } else if (aNum == null && bNum != null) {
        return 1;
      } else {
        // Lexical comparison
        final comp = aPart.toLowerCase().compareTo(bPart.toLowerCase());
        if (comp != 0) return comp;
      }
    }

    return aParts.length.compareTo(bParts.length);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParsedVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, prerelease, buildNumber);

  @override
  String toString() {
    final pre = prerelease != null ? '-$prerelease' : '';
    final build = buildNumber != null ? '+$buildNumber' : '';
    return '$major.$minor.$patch$pre$build';
  }
}

/// Result of parsing a version string.
@immutable
class VersionParseResult {
  final bool isValid;
  final ParsedVersion? version;
  final String? error;

  const VersionParseResult._({
    required this.isValid,
    this.version,
    this.error,
  });

  factory VersionParseResult.success(ParsedVersion version) {
    return VersionParseResult._(isValid: true, version: version);
  }

  factory VersionParseResult.invalid(String error) {
    return VersionParseResult._(isValid: false, error: error);
  }
}

/// Pure utility engine for parsing and comparing versions safely.
class VersionComparator {
  // Regex supporting:
  // v1.2.3, 1.2.3, v1.2.3-beta.1, 1.2.3+45, v1.2.3-rc.1+45, etc.
  static final RegExp _semVerRegex = RegExp(
    r'^[vV]?(?<major>\d+)(?:\.(?<minor>\d+))?(?:\.(?<patch>\d+))?(?:-(?<prerelease>[0-9a-zA-Z\.\-]+))?(?:\+(?<build>[0-9a-zA-Z\.\-]+))?$',
  );

  /// Parse a version string into a [VersionParseResult].
  static VersionParseResult parse(String? rawVersion, {String? explicitBuildNumber}) {
    if (rawVersion == null || rawVersion.trim().isEmpty) {
      return VersionParseResult.invalid('Version string is empty or null');
    }

    final trimmed = rawVersion.trim();
    final match = _semVerRegex.firstMatch(trimmed);

    if (match == null) {
      return VersionParseResult.invalid('Invalid semantic version format: "$rawVersion"');
    }

    try {
      final major = int.parse(match.namedGroup('major')!);
      final minor = match.namedGroup('minor') != null ? int.parse(match.namedGroup('minor')!) : 0;
      final patch = match.namedGroup('patch') != null ? int.parse(match.namedGroup('patch')!) : 0;
      final prerelease = match.namedGroup('prerelease');
      
      // Build number might come from the version string (+build) or explicit build number parameter
      String? buildStr = match.namedGroup('build');
      if ((buildStr == null || buildStr.isEmpty) && explicitBuildNumber != null && explicitBuildNumber.trim().isNotEmpty) {
        buildStr = explicitBuildNumber.trim();
      }

      int? buildNumber;
      if (buildStr != null) {
        buildNumber = int.tryParse(buildStr);
      }

      final parsed = ParsedVersion(
        major: major,
        minor: minor,
        patch: patch,
        prerelease: prerelease,
        buildNumber: buildNumber,
        raw: trimmed,
      );

      return VersionParseResult.success(parsed);
    } catch (e) {
      return VersionParseResult.invalid('Failed to parse version "$rawVersion": $e');
    }
  }

  /// Returns `true` if [latestRaw] is strictly newer than [currentRaw].
  ///
  /// Safe against malformed inputs (returns `false` if either cannot be parsed).
  static bool isNewer({
    required String currentRaw,
    String? currentBuild,
    required String latestRaw,
    String? latestBuild,
  }) {
    final currentResult = parse(currentRaw, explicitBuildNumber: currentBuild);
    final latestResult = parse(latestRaw, explicitBuildNumber: latestBuild);

    if (!currentResult.isValid || !latestResult.isValid) {
      debugPrint('VersionComparator: Parse error. Current: ${currentResult.error}, Latest: ${latestResult.error}');
      return false;
    }

    return latestResult.version!.compareTo(currentResult.version!) > 0;
  }
}
