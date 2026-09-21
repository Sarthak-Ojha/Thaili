import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/core/services/number_formatter.dart';

void main() {
  group('NumberFormatter – NaN and Infinity edge cases', () {
    test('format(NaN) returns "0"', () {
      expect(NumberFormatter.format(double.nan), '0');
    });

    test('format(Infinity) returns "0"', () {
      expect(NumberFormatter.format(double.infinity), '0');
    });

    test('format(-Infinity) returns "0"', () {
      expect(NumberFormatter.format(double.negativeInfinity), '0');
    });

    test('formatPercentage(NaN) returns "0%"', () {
      expect(NumberFormatter.formatPercentage(double.nan), '0%');
    });

    test('formatPercentage(Infinity) returns "0%"', () {
      expect(NumberFormatter.formatPercentage(double.infinity), '0%');
    });
  });

  group('NumberFormatter – negative zero', () {
    test('format(-0.0) does not show minus sign', () {
      // -0.0 < 0 is false in Dart, so it should format as "0"
      final result = NumberFormatter.format(-0.0);
      expect(result.contains('−'), false);
      expect(result, '0');
    });
  });

  group('NumberFormatter – large numbers', () {
    test('formats 1 crore correctly', () {
      expect(NumberFormatter.format(10000000), '1,00,00,000');
    });

    test('formats 1 billion correctly (10 crore)', () {
      expect(NumberFormatter.format(1000000000), '1,00,00,00,000');
    });

    test('formats 999 correctly (under threshold)', () {
      expect(NumberFormatter.format(999), '999');
    });

    test('formats 1000 correctly', () {
      expect(NumberFormatter.format(1000), '1,000');
    });

    test('formats 99999 correctly', () {
      expect(NumberFormatter.format(99999), '99,999');
    });
  });

  group('NumberFormatter – decimal precision', () {
    test('showDecimals: true shows decimal when non-zero cents', () {
      expect(NumberFormatter.format(100.50, showDecimals: true), '100.50');
    });

    test('showDecimals: true does not append .00', () {
      // Integer value should not append decimals
      expect(NumberFormatter.format(100.00, showDecimals: true), '100');
    });

    test('showDecimals: false (default) omits decimals', () {
      expect(NumberFormatter.format(100.75), '100');
    });

    test('showDecimals: true with negative amount', () {
      final result = NumberFormatter.format(-250.50, showDecimals: true);
      expect(result, '−250.50');
    });
  });

  group('NumberFormatter – formatCurrency edge cases', () {
    test('empty symbol returns just the number', () {
      expect(NumberFormatter.formatCurrency(500.0, symbol: ''), '500');
    });

    test('negative amount with symbol formats correctly', () {
      expect(
          NumberFormatter.formatCurrency(-500.0, symbol: 'Rs.'), '− Rs. 500');
    });

    test('positive amount with symbol formats correctly', () {
      expect(NumberFormatter.formatCurrency(1500.0, symbol: '₹'), '₹ 1,500');
    });

    test('zero amount with symbol', () {
      expect(NumberFormatter.formatCurrency(0.0, symbol: '\$'), '\$ 0');
    });
  });

  group('NumberFormatter – formatPercentage options', () {
    test('0 decimal places (default) rounds', () {
      expect(NumberFormatter.formatPercentage(45.678), '46%');
    });

    test('1 decimal place', () {
      expect(NumberFormatter.formatPercentage(45.678, decimalPlaces: 1), '45.7%');
    });

    test('2 decimal places', () {
      expect(NumberFormatter.formatPercentage(33.333, decimalPlaces: 2), '33.33%');
    });

    test('100% formats correctly', () {
      expect(NumberFormatter.formatPercentage(100.0), '100%');
    });

    test('0% formats correctly', () {
      expect(NumberFormatter.formatPercentage(0.0), '0%');
    });
  });
}
