/// Robust Date & DateTime utility functions for Thaili.
class AppDateUtils {
  /// Check if two [DateTime] objects represent the same calendar day.
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Normalize a [DateTime] by stripping the time component (returning midnight).
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if a date is today.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if a date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Check if a date falls within the current calendar month and year.
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Format date relative to today (e.g., "Today", "Yesterday", or "MMM d, yyyy").
  static String formatRelativeDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  /// Check if a formatted date string or DateTime matches a filter period (Today, Yesterday, This Month, etc.).
  static bool matchesPeriodFilter({
    required DateTime itemDate,
    required String filterPeriod,
  }) {
    final periodLower = filterPeriod.toLowerCase().trim();
    if (periodLower.isEmpty || periodLower == 'all' || periodLower == 'all time') {
      return true;
    }
    if (periodLower.contains('today')) {
      return isToday(itemDate);
    }
    if (periodLower.contains('yesterday')) {
      return isYesterday(itemDate);
    }
    if (periodLower.contains('month')) {
      return isThisMonth(itemDate);
    }
    return true;
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
