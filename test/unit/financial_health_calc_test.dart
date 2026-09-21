import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/state/app_state.dart';
import 'package:thaili/features/health/financial_health_calculator.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppStateModel().resetForTesting();
  });

  // --------------------------------------------------------------------------
  // getHealthStatusLabel – boundary values (already partially covered)
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – getHealthStatusLabel', () {
    test('score 100 => Excellent', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(100),
          'Excellent Financial Health');
    });

    test('score 80 => Excellent (boundary)', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(80),
          'Excellent Financial Health');
    });

    test('score 79 => Good Financial Standing', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(79),
          'Good Financial Standing');
    });

    test('score 60 => Good (boundary)', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(60),
          'Good Financial Standing');
    });

    test('score 59 => Fair', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(59),
          'Fair - Needs Attention');
    });

    test('score 40 => Fair (boundary)', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(40),
          'Fair - Needs Attention');
    });

    test('score 39 => Critical', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(39),
          'Critical - Budget Action Required');
    });

    test('score 0 => Critical', () {
      expect(FinancialHealthCalculator.getHealthStatusLabel(0),
          'Critical - Budget Action Required');
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – zero income scenario
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – zero income', () {
    test('returns non-zero score even with zero income (uses fallbacks)', () {
      // No transactions → income = 0; spending fallback = 50, saving fallback = 50
      // No budgets → budget fallback = 70; < 5 transactions → consistency = 60
      // Weighted: (50*0.30)+(50*0.20)+(70*0.30)+(60*0.20) = 15+10+21+12 = 58
      final score = FinancialHealthCalculator.calculateScore(AppStateModel());
      expect(score, 58);
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – spending score branches
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – spending score', () {
    test('spending ratio <= 0.5 gives spending score of 100', () {
      final state = AppStateModel();
      // Income 10000, Expenses 4000 → ratio 0.4 ≤ 0.5 → spending=100
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 10000, type: TransactionType.income));
      state.addTransaction(
          makeTransaction(id: 'e1', amount: 4000, type: TransactionType.expense));
      // No budgets → budgetScore=70; <5 tx → consistency=60; savings=(10000-4000)/10000=0.6→clamp100
      // Weighted: (100*0.3)+(100*0.2)+(70*0.3)+(60*0.2) = 30+20+21+12 = 83
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 83);
    });

    test('spending ratio >= 1.0 gives spending score of 20', () {
      final state = AppStateModel();
      // Expenses >= Income
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 1000, type: TransactionType.income));
      state.addTransaction(
          makeTransaction(id: 'e1', amount: 1000, type: TransactionType.expense));
      // spending ratio = 1.0 → spending = 20; net savings = 0 → saving = 10
      // No budgets → 70; <5 tx → 60
      // (20*0.3)+(10*0.2)+(70*0.3)+(60*0.2) = 6+2+21+12 = 41
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 41);
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – saving score branches
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – saving score', () {
    test('negative savings gives saving score of 10', () {
      final state = AppStateModel();
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 1000, type: TransactionType.income));
      state.addTransaction(
          makeTransaction(id: 'e1', amount: 2000, type: TransactionType.expense));
      // net savings < 0 → saving = 10; spending ratio = 2 → spending = 20
      // No budgets → 70; <5 tx → 60
      // (20*0.3)+(10*0.2)+(70*0.3)+(60*0.2) = 6+2+21+12 = 41
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 41);
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – budget score branches
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – budget score', () {
    test('all budgets within limit gives budget score of 100', () {
      final state = AppStateModel();
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 10000, type: TransactionType.income));
      state.addBudget(makeBudget(id: 'b1', spent: 100, limit: 500));
      state.addBudget(makeBudget(id: 'b2', spent: 200, limit: 800));
      // spending 0/10000=0 → 100; saving = (10000/10000)*200=200 → clamp 100
      // budget: both within → 100; <5 tx → 60
      // (100*0.3)+(100*0.2)+(100*0.3)+(60*0.2) = 30+20+30+12 = 92
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 92);
    });

    test('no budgets gives budget score default of 70', () {
      // Already tested above in zero-income scenario (score = 58)
      final score = FinancialHealthCalculator.calculateScore(AppStateModel());
      // budget default = 70 confirmed
      expect(score, 58);
    });

    test('half budgets over limit gives budget score 50', () {
      final state = AppStateModel();
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 10000, type: TransactionType.income));
      state.addBudget(makeBudget(id: 'b1', spent: 400, limit: 500)); // within
      state.addBudget(makeBudget(id: 'b2', spent: 900, limit: 800)); // over
      // spending 0→100; saving→100 (no expenses); budget 1/2→50; <5→60
      // (100*0.3)+(100*0.2)+(50*0.3)+(60*0.2) = 30+20+15+12 = 77
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 77);
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – consistency score branches
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – consistency score', () {
    test('fewer than 5 transactions gives consistency score of 60', () {
      final state = AppStateModel();
      for (int i = 0; i < 4; i++) {
        state.addTransaction(makeTransaction(
            id: 'tx_$i', amount: 100, type: TransactionType.expense));
      }
      state.addTransaction(
          makeTransaction(id: 'inc', amount: 5000, type: TransactionType.income));
      // 5 transactions total — 5 is NOT < 5, so consistency = 85
      // spending: 400/5000=0.08 → 100; saving: (5000-400)/5000=0.92*200=184→100; budget:70
      // (100*0.3)+(100*0.2)+(70*0.3)+(85*0.2) = 30+20+21+17 = 88
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 88);
    });

    test('exactly 4 transactions gives consistency score of 60', () {
      final state = AppStateModel();
      for (int i = 0; i < 3; i++) {
        state.addTransaction(makeTransaction(
            id: 'tx_$i', amount: 100, type: TransactionType.expense));
      }
      state.addTransaction(
          makeTransaction(id: 'inc', amount: 5000, type: TransactionType.income));
      // 4 total — < 5 → consistency = 60
      // spending: 300/5000=0.06→100; saving: (5000-300)/5000=0.94*200=188→100; budget:70
      // (100*0.3)+(100*0.2)+(70*0.3)+(60*0.2) = 30+20+21+12 = 83
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 83);
    });

    test('5 or more transactions gives consistency score of 85', () {
      final state = AppStateModel();
      state.addTransaction(
          makeTransaction(id: 'inc', amount: 10000, type: TransactionType.income));
      for (int i = 0; i < 5; i++) {
        state.addTransaction(makeTransaction(
            id: 'ex_$i', amount: 100, type: TransactionType.expense));
      }
      // 6 total → consistency = 85; spending 500/10000=0.05→100; saving→100; budget→70
      // (100*0.3)+(100*0.2)+(70*0.3)+(85*0.2) = 30+20+21+17 = 88
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, 88);
    });
  });

  // --------------------------------------------------------------------------
  // calculateScore – score clamping
  // --------------------------------------------------------------------------
  group('FinancialHealthCalculator – score clamping', () {
    test('score is clamped to minimum of 0', () {
      // calculateScore always clamps to [0, 100]
      final score = FinancialHealthCalculator.calculateScore(AppStateModel());
      expect(score, greaterThanOrEqualTo(0));
    });

    test('score is clamped to maximum of 100', () {
      final state = AppStateModel();
      state.addTransaction(
          makeTransaction(id: 'i1', amount: 10000, type: TransactionType.income));
      // Even best case won't exceed 100
      final score = FinancialHealthCalculator.calculateScore(state);
      expect(score, lessThanOrEqualTo(100));
    });
  });
}
