import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/core/services/app_date_utils.dart';

void main() {
  // --------------------------------------------------------------------------
  // isSameDay – null handling
  // --------------------------------------------------------------------------
  group('AppDateUtils – isSameDay null handling', () {
    test('returns false when first date is null', () {
      expect(AppDateUtils.isSameDay(null, DateTime(2026, 9, 1)), false);
    });

    test('returns false when second date is null', () {
      expect(AppDateUtils.isSameDay(DateTime(2026, 9, 1), null), false);
    });

    test('returns false when both dates are null', () {
      expect(AppDateUtils.isSameDay(null, null), false);
    });
  });

  // --------------------------------------------------------------------------
  // isThisMonth
  // --------------------------------------------------------------------------
  group('AppDateUtils – isThisMonth', () {
    test('returns true for a date in current month/year', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      expect(AppDateUtils.isThisMonth(thisMonth), true);
    });

    test('returns false for a date in previous month', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1 == 0 ? 12 : now.month - 1, 1);
      expect(AppDateUtils.isThisMonth(lastMonth), false);
    });

    test('returns false for a date in previous year', () {
      final lastYear = DateTime(DateTime.now().year - 1, 1, 1);
      expect(AppDateUtils.isThisMonth(lastYear), false);
    });
  });

  // --------------------------------------------------------------------------
  // matchesPeriodFilter
  // --------------------------------------------------------------------------
  group('AppDateUtils – matchesPeriodFilter', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastMonth = DateTime(now.year, now.month - 1 == 0 ? 12 : now.month - 1, 15);

    test('empty filter matches any date', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: lastMonth, filterPeriod: ''), true);
    });

    test('"all" filter matches any date', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: lastMonth, filterPeriod: 'All'), true);
    });

    test('"all time" filter matches any date', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: lastMonth, filterPeriod: 'All Time'), true);
    });

    test('"Today" filter matches today', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: now, filterPeriod: 'Today'), true);
    });

    test('"Today" filter does not match yesterday', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: yesterday, filterPeriod: 'Today'), false);
    });

    test('"Yesterday" filter matches yesterday', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: yesterday, filterPeriod: 'Yesterday'), true);
    });

    test('"Yesterday" filter does not match today', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: now, filterPeriod: 'Yesterday'), false);
    });

    test('"This Month" filter matches date in current month', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: now, filterPeriod: 'This Month'), true);
    });

    test('"This Month" filter does not match last month', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: lastMonth, filterPeriod: 'This Month'), false);
    });

    test('unknown filter returns true (pass-through)', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: lastMonth, filterPeriod: 'Last Week'), true);
    });

    test('case insensitive matching for "today"', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: now, filterPeriod: 'TODAY'), true);
    });

    test('case insensitive matching for "yesterday"', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: yesterday, filterPeriod: 'YESTERDAY'), true);
    });

    test('case insensitive matching for "month"', () {
      expect(AppDateUtils.matchesPeriodFilter(itemDate: now, filterPeriod: 'THIS MONTH'), true);
    });
  });

  // --------------------------------------------------------------------------
  // formatRelativeDate
  // --------------------------------------------------------------------------
  group('AppDateUtils – formatRelativeDate', () {
    test('returns "Today" for current date', () {
      expect(AppDateUtils.formatRelativeDate(DateTime.now()), 'Today');
    });

    test('returns "Yesterday" for previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.formatRelativeDate(yesterday), 'Yesterday');
    });

    test('returns formatted date string for older dates', () {
      final oldDate = DateTime(2025, 1, 15);
      expect(AppDateUtils.formatRelativeDate(oldDate), 'Jan 15, 2025');
    });

    test('formats December correctly', () {
      final date = DateTime(2024, 12, 31);
      expect(AppDateUtils.formatRelativeDate(date), 'Dec 31, 2024');
    });
  });

  // --------------------------------------------------------------------------
  // normalizeDate – boundary and leap year cases
  // --------------------------------------------------------------------------
  group('AppDateUtils – normalizeDate boundary cases', () {
    test('normalizes last day of month correctly', () {
      final date = DateTime(2026, 1, 31, 23, 59, 59);
      final normalized = AppDateUtils.normalizeDate(date);
      expect(normalized.day, 31);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
    });

    test('normalizes Feb 29 on leap year (2024)', () {
      final leapDay = DateTime(2024, 2, 29, 12, 0, 0);
      final normalized = AppDateUtils.normalizeDate(leapDay);
      expect(normalized.year, 2024);
      expect(normalized.month, 2);
      expect(normalized.day, 29);
      expect(normalized.hour, 0);
    });

    test('normalizes Dec 31 (year boundary)', () {
      final yearEnd = DateTime(2025, 12, 31, 11, 59, 59);
      final normalized = AppDateUtils.normalizeDate(yearEnd);
      expect(normalized.year, 2025);
      expect(normalized.month, 12);
      expect(normalized.day, 31);
      expect(normalized.hour, 0);
    });
  });
}
