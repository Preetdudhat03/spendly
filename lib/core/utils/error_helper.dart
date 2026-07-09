import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHelper {
  /// Converts any exception into a safe, generic, user-facing error message
  /// while logging the full exception detail and stack trace for developer debugging.
  static String getReadableErrorMessage(Object error, [StackTrace? stackTrace]) {
    // Log the full detail internally
    if (kDebugMode) {
      debugPrint('--- INTERNAL ERROR LOG ---');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stacktrace:\n$stackTrace');
      }
      debugPrint('--------------------------');
    }

    if (error is PostgrestException) {
      // Obfuscate raw SQL/Postgres error messages.
      // Match specific constraint names if safe, otherwise return generic.
      final code = error.code;
      if (code == '23505') {
        return 'This record already exists in the database.';
      } else if (code == '23503') {
        return 'Related database record was not found.';
      }
      return 'A secure database operation failed. Please try again.';
    }

    if (error is AuthException) {
      // Supabase Auth exceptions are generally safe to show as they relate to client input.
      // However, we sanitize internal codes/messages if any leak.
      final msg = error.message.toLowerCase();
      if (msg.contains('database') || msg.contains('relation') || msg.contains('row')) {
        return 'An internal authentication error occurred. Please try again.';
      }
      return error.message;
    }

    if (error is SocketException || error.toString().contains('SocketException')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    if (error is HttpException || error.toString().contains('HttpException')) {
      return 'Server communication failed. Please try again later.';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('clientexception') || errStr.contains('failed host lookup')) {
      return 'Unable to reach Spendly servers. Please check your internet connection.';
    }

    if (errStr.contains('schema_validation_exception') || error.toString().startsWith('SchemaValidationException:')) {
      return error.toString().replaceFirst('SchemaValidationException:', '').trim();
    }

    // Default generic fallback
    return 'An unexpected error occurred. Please try again.';
  }
}
