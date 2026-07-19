import 'package:intl/intl.dart';

/// Formatting helpers for the dashboard, mirroring the web app's
/// `src/app/(protected)/dashboard/shared/format.ts`.
class CurrencyUtils {
  CurrencyUtils._(); // prevent instantiation

  /// e.g. 1234567 -> "1.234.567 ₫"
  static String formatVND(num value) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(value);
  }

  /// e.g. 1234567 -> "1,2Tr ₫" (compact notation, max 1 fraction digit)
  static String formatCompactVND(num value) {
    return NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 1,
    ).format(value);
  }

  /// e.g. 1234567 -> "1.234.567"
  static String formatNumber(num value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }

  /// e.g. 12.3 -> "+12.3%", -5 -> "-5%", null -> "—"
  static String formatPercent(num? value) {
    if (value == null) return '—';
    final sign = value > 0 ? '+' : '';
    final display = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$sign$display%';
  }
}
