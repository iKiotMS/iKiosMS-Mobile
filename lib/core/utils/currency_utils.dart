/// Helpers for formatting Vietnamese đồng (VND) amounts.
///
/// The backend stores money as plain integers of VND (no decimals), matching
/// the dashboard. We group thousands with a dot — "1.500.000 ₫" — which is the
/// Vietnamese convention.
class CurrencyUtils {
  CurrencyUtils._(); // prevent instantiation

  /// Formats a VND amount with dot thousands separators, e.g. 1500000 → "1.500.000 ₫".
  static String formatVnd(num amount) {
    return '${_groupThousands(amount.round())} ₫';
  }

  /// Formats a signed VND amount, prefixing "+" for income and "-" for expense,
  /// e.g. income 50000 → "+50.000 ₫", expense 20000 → "-20.000 ₫".
  static String formatSignedVnd(num amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${formatVnd(amount.abs())}';
  }

  /// Groups an integer's digits into dot-separated thousands.
  static String _groupThousands(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return isNegative ? '-$buffer' : buffer.toString();
  }
}
