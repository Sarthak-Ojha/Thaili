import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/core/state/app_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BudgetItem – percent calculation', () {
    test('percent is correct when within budget', () {
      final b = makeBudget(spent: 250.0, limit: 500.0);
      expect(b.percent, closeTo(50.0, 0.001));
    });

    test('percent is 100 when spent equals limit', () {
      final b = makeBudget(spent: 500.0, limit: 500.0);
      expect(b.percent, closeTo(100.0, 0.001));
    });

    test('percent exceeds 100 when over budget', () {
      final b = makeBudget(spent: 600.0, limit: 500.0);
      expect(b.percent, closeTo(120.0, 0.001));
    });

    test('percent is 0 when limit is 0 (no division by zero)', () {
      final b = makeBudget(spent: 0.0, limit: 0.0);
      expect(b.percent, 0.0);
    });

    test('percent is 0 when spent is 0', () {
      final b = makeBudget(spent: 0.0, limit: 1000.0);
      expect(b.percent, 0.0);
    });

    test('percent rounds correctly with non-integer values', () {
      final b = makeBudget(spent: 333.33, limit: 1000.0);
      expect(b.percent, closeTo(33.333, 0.001));
    });

    test('alertPercent defaults to 80', () {
      const b = BudgetItem(
        id: 'x', category: 'test', emoji: '🧪', spent: 0, limit: 1000,
      );
      expect(b.alertPercent, 80);
    });

    test('period defaults to Monthly', () {
      const b = BudgetItem(
        id: 'x', category: 'test', emoji: '🧪', spent: 0, limit: 1000,
      );
      expect(b.period, 'Monthly');
    });
  });
}
