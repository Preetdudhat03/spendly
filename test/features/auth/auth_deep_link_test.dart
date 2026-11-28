import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/auth_deep_link_service.dart';

void main() {
  group('AuthDeepLinkService.parseCallbackUri', () {
    test('parses signup confirmation callback', () {
      final uri = Uri.parse('spendly://auth-callback?type=signup&code=abc123');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.signup);
      expect(res.isSuccess, isTrue);
      expect(res.code, 'abc123');
    });

    test('parses email change confirmation callback', () {
      final uri = Uri.parse('spendly://auth-callback?type=email_change&code=xyz789');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.emailChange);
      expect(res.isSuccess, isTrue);
      expect(res.code, 'xyz789');
    });

    test('parses password recovery callback', () {
      final uri = Uri.parse('spendly://reset-password?type=recovery&code=rec456');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.recovery);
      expect(res.isSuccess, isTrue);
    });

    test('parses OTP magiclink callback', () {
      final uri = Uri.parse('spendly://auth-callback?type=magiclink&code=otp999');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.otp);
      expect(res.isSuccess, isTrue);
    });

    test('handles expired token in query params', () {
      final uri = Uri.parse(
        'spendly://auth-callback?error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired',
      );
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.error);
      expect(res.isError, isTrue);
      expect(res.errorMessage, contains('expired'));
    });

    test('handles invalid token in fragment', () {
      final uri = Uri.parse(
        'spendly://auth-callback#error=access_denied&error_description=Token+invalid',
      );
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.error);
      expect(res.isError, isTrue);
      expect(res.errorMessage, contains('invalid'));
    });

    test('rejects incomplete callback without token or code', () {
      final uri = Uri.parse('spendly://auth-callback');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.error);
      expect(res.errorCode, 'missing_token');
    });

    test('rejects untrusted redirect destination host', () {
      final uri = Uri.parse('spendly://evil-redirect?code=123');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.error);
      expect(res.errorCode, 'invalid_redirect');
    });

    test('ignores non-spendly schemes', () {
      final uri = Uri.parse('https://example.com/auth-callback?code=123');
      final res = AuthDeepLinkService.parseCallbackUri(uri);
      expect(res.kind, AuthCallbackKind.ignored);
    });
  });
}
