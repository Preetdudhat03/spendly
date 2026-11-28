import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/constants/auth_constants.dart';

enum AuthCallbackKind {
  signup,
  emailChange,
  recovery,
  otp,
  sessionRestored,
  error,
  ignored,
}

class AuthCallbackResult {
  final AuthCallbackKind kind;
  final Uri? uri;
  final String? code;
  final String? tokenHash;
  final String? errorCode;
  final String? errorMessage;
  final bool hasSessionPayload;

  const AuthCallbackResult({
    required this.kind,
    this.uri,
    this.code,
    this.tokenHash,
    this.errorCode,
    this.errorMessage,
    this.hasSessionPayload = false,
  });

  bool get isError => kind == AuthCallbackKind.error;
  bool get isSuccess =>
      kind == AuthCallbackKind.signup ||
      kind == AuthCallbackKind.emailChange ||
      kind == AuthCallbackKind.recovery ||
      kind == AuthCallbackKind.otp ||
      kind == AuthCallbackKind.sessionRestored;
}

class AuthDeepLinkService {
  /// Allowed Spendly callback hosts for `spendly://`.
  static const Set<String> _allowedHosts = {
    AuthConstants.authCallbackHost,
    AuthConstants.resetPasswordHost,
  };

  /// Parses an incoming [Uri] into an [AuthCallbackResult].
  /// Rejects arbitrary/untrusted redirect destinations.
  static AuthCallbackResult parseCallbackUri(Uri uri) {
    if (uri.scheme.toLowerCase() != AuthConstants.appScheme) {
      return AuthCallbackResult(kind: AuthCallbackKind.ignored, uri: uri);
    }

    final host = uri.host.toLowerCase();
    if (!_allowedHosts.contains(host)) {
      return AuthCallbackResult(
        kind: AuthCallbackKind.error,
        uri: uri,
        errorCode: 'invalid_redirect',
        errorMessage: 'Unrecognized authentication redirect destination.',
      );
    }

    final params = <String, String>{};
    params.addAll(uri.queryParameters);
    if (uri.fragment.isNotEmpty) {
      try {
        params.addAll(Uri.splitQueryString(uri.fragment));
      } catch (_) {
        // Ignore malformed fragment
      }
    }

    final error = params['error'];
    final errorCode = params['error_code'];
    final errorDescription = params['error_description'];

    if (error != null || errorCode != null || errorDescription != null) {
      return AuthCallbackResult(
        kind: AuthCallbackKind.error,
        uri: uri,
        errorCode: errorCode ?? error,
        errorMessage: mapCallbackError(
          errorCode: errorCode ?? error,
          description: errorDescription,
        ),
      );
    }

    final type = params['type']?.toLowerCase();
    final code = params['code'];
    final tokenHash = params['token_hash'];
    final accessToken = params['access_token'];
    final hasSessionPayload =
        (code != null && code.isNotEmpty) ||
        (accessToken != null && accessToken.isNotEmpty) ||
        (tokenHash != null && tokenHash.isNotEmpty);

    if (host == AuthConstants.resetPasswordHost || type == 'recovery') {
      return AuthCallbackResult(
        kind: AuthCallbackKind.recovery,
        uri: uri,
        code: code,
        tokenHash: tokenHash,
        hasSessionPayload: hasSessionPayload,
      );
    }

    switch (type) {
      case 'signup':
        return AuthCallbackResult(
          kind: AuthCallbackKind.signup,
          uri: uri,
          code: code,
          tokenHash: tokenHash,
          hasSessionPayload: hasSessionPayload,
        );
      case 'email_change':
        return AuthCallbackResult(
          kind: AuthCallbackKind.emailChange,
          uri: uri,
          code: code,
          tokenHash: tokenHash,
          hasSessionPayload: hasSessionPayload,
        );
      case 'magiclink':
      case 'email':
        return AuthCallbackResult(
          kind: AuthCallbackKind.otp,
          uri: uri,
          code: code,
          tokenHash: tokenHash,
          hasSessionPayload: hasSessionPayload,
        );
      default:
        if (hasSessionPayload) {
          return AuthCallbackResult(
            kind: AuthCallbackKind.sessionRestored,
            uri: uri,
            code: code,
            tokenHash: tokenHash,
            hasSessionPayload: true,
          );
        }
        return AuthCallbackResult(
          kind: AuthCallbackKind.error,
          uri: uri,
          errorCode: 'missing_token',
          errorMessage:
              'This verification link is incomplete or invalid. Please request a new one.',
        );
    }
  }

  static String mapCallbackError({String? errorCode, String? description}) {
    final normalizedCode = (errorCode ?? '').toLowerCase();
    final normalizedDesc = (description ?? '').toLowerCase();

    if (normalizedCode.contains('otp_expired') ||
        normalizedDesc.contains('expired')) {
      return 'This verification link has expired. Please request a new confirmation email.';
    }
    if (normalizedCode.contains('access_denied') ||
        normalizedDesc.contains('invalid') ||
        normalizedDesc.contains('already')) {
      return 'This verification link is invalid or has already been used.';
    }
    if (description != null && description.trim().isNotEmpty) {
      return Uri.decodeComponent(description).replaceAll('+', ' ');
    }
    return 'Email verification failed. Please request a new link and try again.';
  }

  StreamSubscription<Uri>? _linkSub;

  void startListening({
    required void Function(AuthCallbackResult result) onCallback,
  }) {
    if (kIsWeb) return;

    final appLinks = AppLinks();

    // Handle initial link when app was launched from terminated state
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        final result = parseCallbackUri(uri);
        if (result.kind != AuthCallbackKind.ignored) {
          onCallback(result);
        }
      }
    }).catchError((e) {
      debugPrint('AuthDeepLinkService: getInitialLink error: $e');
    });

    // Handle incoming links while app is running
    _linkSub?.cancel();
    _linkSub = appLinks.uriLinkStream.listen(
      (uri) {
        final result = parseCallbackUri(uri);
        if (result.kind != AuthCallbackKind.ignored) {
          onCallback(result);
        }
      },
      onError: (e) {
        debugPrint('AuthDeepLinkService: uriLinkStream error: $e');
      },
    );
  }

  /// Completes Supabase session exchange if needed for a parsed callback URI.
  static Future<void> exchangeSessionIfNeeded(AuthCallbackResult result) async {
    if (result.uri == null || !result.hasSessionPayload) return;
    try {
      await Supabase.instance.client.auth
          .getSessionFromUrl(result.uri!)
          .timeout(AuthConstants.networkTimeout);
    } on AuthException {
      rethrow;
    } catch (e) {
      // supabase_flutter may have already exchanged the PKCE code automatically
      debugPrint('AuthDeepLinkService: getSessionFromUrl note: $e');
    }
  }

  void dispose() {
    _linkSub?.cancel();
    _linkSub = null;
  }
}
