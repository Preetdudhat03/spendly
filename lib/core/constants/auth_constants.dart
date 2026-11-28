class AuthConstants {
  static const String appScheme = 'spendly';
  static const String authCallbackHost = 'auth-callback';
  static const String resetPasswordHost = 'reset-password';

  static const String authCallbackUri = '$appScheme://$authCallbackHost';
  static const String resetPasswordUri = '$appScheme://$resetPasswordHost';

  static const Duration networkTimeout = Duration(seconds: 15);
  static const int resendCooldownSeconds = 60;

  /// Masks an email address for safe display on OTP and verification screens.
  /// Example: `dudhatpreet@gmail.com` -> `du*****@gmail.com`
  static String maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return trimmed;
    }
    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    if (local.length <= 2) {
      return '${local[0]}***$domain';
    }
    return '${local.substring(0, 2)}*****$domain';
  }
}
