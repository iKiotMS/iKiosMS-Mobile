/// Helper utilities for date/time operations used throughout the app.
///
/// Vietnamese weekday abbreviations:
///   Mon=Th.2, Tue=Th.3, Wed=Th.4, Thu=Th.5, Fri=Th.6, Sat=Th.7, Sun=CN
class DateTimeUtils {
  DateTimeUtils._(); // prevent instantiation

  // Vietnamese abbreviated weekday names (1=Monday ... 7=Sunday)
  static const _viWeekdayShort = {
    1: 'Th.2',
    2: 'Th.3',
    3: 'Th.4',
    4: 'Th.5',
    5: 'Th.6',
    6: 'Th.7',
    7: 'CN',
  };

  // Full Vietnamese weekday names
  static const _viWeekdayFull = {
    1: 'Thứ Hai',
    2: 'Thứ Ba',
    3: 'Thứ Tư',
    4: 'Thứ Năm',
    5: 'Thứ Sáu',
    6: 'Thứ Bảy',
    7: 'Chủ Nhật',
  };

  /// Returns the Monday of the week that contains [date].
  static DateTime getStartOfWeek(DateTime date) {
    // weekday: 1=Mon, 7=Sun
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Returns the Sunday of the week that contains [date].
  static DateTime getEndOfWeek(DateTime date) {
    final start = getStartOfWeek(date);
    return start.add(const Duration(days: 6));
  }

  /// Formats a [DateTime] as "yyyy-MM-dd" for API query parameters.
  static String formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats a week range as "Th.2 20/6 - CN 27/6".
  ///
  /// [start] must be a Monday, [end] must be the following Sunday.
  static String formatWeekRangeLabel(DateTime start, DateTime end) {
    final startDay = _viWeekdayShort[start.weekday] ?? '';
    final endDay = _viWeekdayShort[end.weekday] ?? '';
    final startLabel = '$startDay ${start.day}/${start.month}';
    final endLabel = '$endDay ${end.day}/${end.month}';
    return '$startLabel - $endLabel';
  }

  /// Formats a shift time range, e.g. "08:00 - 17:00".
  ///
  /// [startTime] and [endTime] are expected in "HH:mm" or "HH:mm:ss" format.
  static String formatTimeRange(String startTime, String endTime) {
    return '${_trimSeconds(startTime)} - ${_trimSeconds(endTime)}';
  }

  /// Formats a date as full Vietnamese day, e.g. "Thứ Hai, 20/06/2026".
  static String formatShiftDate(DateTime date) {
    final weekday = _viWeekdayFull[date.weekday] ?? '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$weekday, $d/$m/${date.year}';
  }

  /// Formats a short date, e.g. "20/06".
  static String formatShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  /// Returns the Vietnamese abbreviated weekday for a given [date].
  static String viWeekdayShort(DateTime date) {
    return _viWeekdayShort[date.weekday] ?? '';
  }

  /// Checks if two dates represent the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Removes seconds from a time string: "08:00:00" → "08:00".
  static String _trimSeconds(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  /// Backend `/stats/revenue` only returns buckets that have orders (sparse).
  /// Fills the full [fromDate]..[toDate] range so the chart still shows every
  /// date/month mark even when a bucket has no data.
  ///
  /// Mirrors the web dashboard's `generateDateBuckets` (shared/format.ts).
  /// [groupBy] is `'day'` (bucket format `yyyy-MM-dd`) or `'month'` (`yyyy-MM`).
  static List<String> generateDateBuckets(
    DateTime fromDate,
    DateTime toDate,
    String groupBy,
  ) {
    final buckets = <String>[];

    if (groupBy == 'month') {
      var cursor = DateTime(fromDate.year, fromDate.month, 1);
      final endCursor = DateTime(toDate.year, toDate.month, 1);
      while (!cursor.isAfter(endCursor)) {
        buckets.add(
          '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}',
        );
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      return buckets;
    }

    var cursor = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day);
    while (!cursor.isAfter(end)) {
      buckets.add(formatApiDate(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return buckets;
  }
}
