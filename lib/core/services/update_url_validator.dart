import 'package:flutter/foundation.dart';

/// Secure URL validation for update destinations and APK downloads.
class UpdateUrlValidator {
  static const String _allowedRepoOwner = 'preetdudhat03';
  static const String _allowedRepoName = 'spendly';

  static final Set<String> _allowedHosts = {
    'github.com',
    'api.github.com',
    'objects.githubusercontent.com',
    'raw.githubusercontent.com',
  };

  /// Returns `true` if the given [urlString] is a trusted, secure update or asset URL.
  static bool isAllowed(String? urlString) {
    if (urlString == null || urlString.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) return false;

    // 1. Must use HTTPS
    if (uri.scheme.toLowerCase() != 'https') {
      debugPrint('UpdateUrlValidator: Rejected insecure scheme "${uri.scheme}" in $urlString');
      return false;
    }

    final host = uri.host.toLowerCase();

    // 2. Validate host
    // Check direct match or trusted GitHub release asset CDN
    final isDirectTrustedHost = _allowedHosts.contains(host);
    final isGitHubS3Cdn = host.endsWith('.githubusercontent.com') ||
        (host.endsWith('.amazonaws.com') && host.contains('github-production-release-asset'));

    if (!isDirectTrustedHost && !isGitHubS3Cdn) {
      debugPrint('UpdateUrlValidator: Rejected untrusted host "$host" in $urlString');
      return false;
    }

    // 3. If the host is github.com, verify the repository namespace belongs to Spendly
    if (host == 'github.com') {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final owner = segments[0].toLowerCase();
        final repo = segments[1].toLowerCase();
        if (owner != _allowedRepoOwner || repo != _allowedRepoName) {
          debugPrint('UpdateUrlValidator: Rejected non-matching GitHub repository: $owner/$repo');
          return false;
        }
      }
    }

    return true;
  }
}
