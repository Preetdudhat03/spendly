import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats currency amounts dynamically:
  /// - Whole numbers (e.g. 1500.0) format cleanly as ₹1,500
  /// - Fractional amounts (e.g. 10.7, 10.75) format with 2 decimals as ₹10.70 / ₹10.75
  static String format(
    double amount, {
    String symbol = '₹',
    String locale = 'en_IN',
    bool forceDecimals = false,
  }) {
    final hasDecimals = (amount % 1 != 0);
    final decimalDigits = (hasDecimals || forceDecimals) ? 2 : 0;
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  /// Converts a numeric amount to a text representation for form fields.
  /// E.g. 10.0 -> "10", 10.7 -> "10.70", 10.75 -> "10.75"
  static String toEditString(double amount) {
    if (amount % 1 == 0) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}
