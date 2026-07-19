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

  /// Alias for [formatVnd].
  static String formatVND(num amount) => formatVnd(amount);

  /// Formats a signed VND amount, prefixing "+" for income and "-" for expense,
  /// e.g. income 50000 → "+50.000 ₫", expense 20000 → "-20.000 ₫".
  static String formatSignedVnd(num amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${formatVnd(amount.abs())}';
  }

  /// Formats a number with dot thousands separators without currency symbol, e.g. 1500000 → "1.500.000".
  static String formatNumber(num amount) {
    return _groupThousands(amount.round());
  }

  /// Formats a percentage value, e.g. 12.5 → "12.5%", -5 → "5%".
  static String formatPercent(num? percent) {
    if (percent == null) return '0%';
    final abs = percent.abs();
    if (abs == abs.roundToDouble()) {
      return '${abs.toInt()}%';
    }
    return '${abs.toStringAsFixed(1)}%';
  }

  /// Formats a VND amount compactly (e.g. 1.5 M ₫, 500 K ₫, 2 B ₫).
  static String formatCompactVND(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000000) {
      final val = abs / 1000000000;
      final formatted = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
      return '$sign$formatted B ₫';
    } else if (abs >= 1000000) {
      final val = abs / 1000000;
      final formatted = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
      return '$sign$formatted M ₫';
    } else if (abs >= 1000) {
      final val = abs / 1000;
      final formatted = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
      return '$sign$formatted K ₫';
    }
    return formatVnd(amount);
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
