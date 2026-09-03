import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/core/services/app_date_utils.dart';
import 'package:thaili/core/services/category_manager.dart';
import 'package:thaili/core/services/money.dart';
import 'package:thaili/core/services/number_formatter.dart';
import 'package:thaili/core/services/transaction_validator.dart';
import 'package:thaili/core/theme/app_constants.dart';
import 'package:thaili/features/health/financial_health_calculator.dart';

void main() {
  group('NumberFormatter Tests', () {
    test('formats South Asian style numbers correctly', () {
      expect(NumberFormatter.format(100), '100');
      expect(NumberFormatter.format(1500), '1,500');
      expect(NumberFormatter.format(100000), '1,00,000');
      expect(NumberFormatter.format(10000000), '1,00,00,000');
    });

    test('formats currency with symbols', () {
      expect(NumberFormatter.formatCurrency(500, symbol: 'Rs.'), 'Rs. 500');
      expect(NumberFormatter.formatCurrency(-250, symbol: 'Rs.'), '− Rs. 250');
    });

    test('formats percentage correctly', () {
      expect(NumberFormatter.formatPercentage(45.5, decimalPlaces: 1), '45.5%');
      expect(NumberFormatter.formatPercentage(80), '80%');
    });
  });

  group('AppDateUtils Tests', () {
    test('isSameDay matches correct dates regardless of time', () {
      final date1 = DateTime(2026, 9, 2, 10, 30);
      final date2 = DateTime(2026, 9, 2, 23, 59);
      final date3 = DateTime(2026, 9, 3, 10, 30);

      expect(AppDateUtils.isSameDay(date1, date2), true);
      expect(AppDateUtils.isSameDay(date1, date3), false);
    });

    test('normalizeDate zeroes out time', () {
      final date = DateTime(2026, 9, 2, 15, 45, 12);
      final normalized = AppDateUtils.normalizeDate(date);

      expect(normalized.year, 2026);
      expect(normalized.month, 9);
      expect(normalized.day, 2);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
    });

    test('isToday and isYesterday check accurately', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      expect(AppDateUtils.isToday(today), true);
      expect(AppDateUtils.isYesterday(yesterday), true);
      expect(AppDateUtils.isToday(yesterday), false);
      expect(AppDateUtils.isYesterday(twoDaysAgo), false);
    });
  });

  group('Money Precision Tests', () {
    test('arithmetic precision without floating point inaccuracies', () {
      final m1 = Money.fromDouble(0.1);
      final m2 = Money.fromDouble(0.2);
      final sum = m1 + m2;

      expect(sum.toDouble(), 0.30);
      expect(sum.paisa, 30);
    });

    test('comparison operations', () {
      final small = Money.fromDouble(10.0);
      final big = Money.fromDouble(50.0);

      expect(small.compareTo(big) < 0, true);
      expect(big.isPositive, true);
    });
  });

  group('TransactionValidator Tests', () {
    test('validates transaction amount correctly', () {
      expect(TransactionValidator.validateAmount(''), 'Please enter an amount');
      expect(TransactionValidator.validateAmount('abc'), 'Please enter a valid number');
      expect(TransactionValidator.validateAmount('0'), 'Amount must be greater than zero');
      expect(TransactionValidator.validateAmount('-50'), 'Amount must be greater than zero');
      expect(TransactionValidator.validateAmount('1500'), null);
      expect(TransactionValidator.validateAmount('1,500'), null);
    });

    test('validates transaction title correctly', () {
      expect(TransactionValidator.validateTitle(''), 'Title cannot be empty');
      expect(TransactionValidator.validateTitle('   '), 'Title cannot be empty');
      expect(TransactionValidator.validateTitle('Groceries'), null);
      expect(
        TransactionValidator.validateTitle('A' * (AppConstants.maxTitleLength + 5)),
        'Title must be ${AppConstants.maxTitleLength} characters or less',
      );
    });
  });

  group('CategoryManager Tests', () {
    test('provides default categories', () {
      expect(CategoryManager.defaultCategories.isNotEmpty, true);
      final foodCat = CategoryManager.getCategoryByName('Food & Dining');
      expect(foodCat.emoji, '🍔');
    });
  });

  group('FinancialHealthCalculator Tests', () {
    test('returns health status labels based on score range', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(85), 'Excellent Financial Health');
      expect(FinancialHealthCalculator.getHealthStatusLabel(65), 'Good Financial Standing');
      expect(FinancialHealthCalculator.getHealthStatusLabel(45), 'Fair - Needs Attention');
      expect(FinancialHealthCalculator.getHealthStatusLabel(25), 'Critical - Budget Action Required');
    });
  });
}
