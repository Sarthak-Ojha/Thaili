import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  // --------------------------------------------------------------------------
  // FinancialGoal – computed integer paisa properties
  // --------------------------------------------------------------------------
  group('FinancialGoal – paisa conversions', () {
    test('targetInPaisa converts correctly', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 0.0);
      expect(goal.targetInPaisa, 10000);
    });

    test('currentInPaisa converts correctly', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 50.50);
      expect(goal.currentInPaisa, 5050);
    });

    test('remainingInPaisa returns difference when current < target', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 30.0);
      expect(goal.remainingInPaisa, 7000);
    });

    test('remainingInPaisa clamps to 0 when current exceeds target', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 150.0);
      expect(goal.remainingInPaisa, 0);
    });

    test('remaining double is correctly derived from remainingInPaisa', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 30.0);
      expect(goal.remaining, closeTo(70.0, 0.001));
    });

    test('remaining is 0.0 when current equals target', () {
      final goal = makeGoal(targetAmount: 500.0, currentAmount: 500.0);
      expect(goal.remaining, closeTo(0.0, 0.001));
    });
  });

  // --------------------------------------------------------------------------
  // FinancialGoal – percent and progressFactor
  // --------------------------------------------------------------------------
  group('FinancialGoal – percent and progressFactor', () {
    test('percent is correct at 25% progress', () {
      final goal = makeGoal(targetAmount: 1000.0, currentAmount: 250.0);
      expect(goal.percent, closeTo(25.0, 0.01));
    });

    test('percent is 100% when fully achieved', () {
      final goal = makeGoal(targetAmount: 1000.0, currentAmount: 1000.0);
      expect(goal.percent, closeTo(100.0, 0.01));
    });

    test('percent is 0% when target is zero (no division by zero)', () {
      final goal = makeGoal(targetAmount: 0.0, currentAmount: 0.0);
      expect(goal.percent, 0.0);
    });

    test('percent exceeds 100 when current > target (no clamp on percent)', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 200.0);
      expect(goal.percent, greaterThan(100.0));
    });

    test('progressFactor is between 0.0 and 1.0', () {
      final goal = makeGoal(targetAmount: 1000.0, currentAmount: 500.0);
      expect(goal.progressFactor, closeTo(0.5, 0.001));
      expect(goal.progressFactor, greaterThanOrEqualTo(0.0));
      expect(goal.progressFactor, lessThanOrEqualTo(1.0));
    });

    test('progressFactor clamps at 1.0 when current > target', () {
      final goal = makeGoal(targetAmount: 100.0, currentAmount: 300.0);
      expect(goal.progressFactor, 1.0);
    });

    test('progressFactor is 0.0 when target is zero', () {
      final goal = makeGoal(targetAmount: 0.0, currentAmount: 0.0);
      expect(goal.progressFactor, 0.0);
    });
  });

  // --------------------------------------------------------------------------
  // FinancialGoal – monthsToReachGoal
  // --------------------------------------------------------------------------
  group('FinancialGoal – monthsToReachGoal', () {
    test('returns 0 when savingsRate is zero', () {
      final goal = makeGoal(targetAmount: 10000.0, currentAmount: 0.0);
      expect(goal.monthsToReachGoal(0), 0);
    });

    test('returns 0 when savingsRate is negative', () {
      final goal = makeGoal(targetAmount: 10000.0, currentAmount: 0.0);
      expect(goal.monthsToReachGoal(-500), 0);
    });

    test('returns ceil of months when remaining is not divisible', () {
      // remaining = 7500, rate = 1000 => 7.5 => ceil => 8
      final goal = makeGoal(targetAmount: 10000.0, currentAmount: 2500.0);
      expect(goal.monthsToReachGoal(1000), 8);
    });

    test('returns exact months when evenly divisible', () {
      // remaining = 5000, rate = 1000 => exactly 5
      final goal = makeGoal(targetAmount: 10000.0, currentAmount: 5000.0);
      expect(goal.monthsToReachGoal(1000), 5);
    });

    test('returns 0 months when goal is already achieved', () {
      // remaining = 0 => 0/rate = 0 => ceil(0) = 0
      final goal = makeGoal(targetAmount: 1000.0, currentAmount: 1000.0);
      expect(goal.monthsToReachGoal(500), 0);
    });

    test('returns 1 month when remaining is less than one month savings', () {
      // remaining = 100, rate = 1000 => 0.1 => ceil => 1
      final goal = makeGoal(targetAmount: 1100.0, currentAmount: 1000.0);
      expect(goal.monthsToReachGoal(1000), 1);
    });
  });
}
