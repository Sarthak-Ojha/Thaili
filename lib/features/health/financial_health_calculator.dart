import '../../core/state/app_state.dart';

/// Improved modular financial health score calculator for Thaili.
class FinancialHealthCalculator {
  /// Calculates overall score (0 - 100) based on spending ratio, budget compliance, savings rate, and consistency.
  static int calculateScore(AppStateModel state) {
    final spendingScore = _calculateSpendingScore(state);
    final savingScore = _calculateSavingScore(state);
    final budgetScore = _calculateBudgetScore(state);
    final consistencyScore = _calculateConsistencyScore(state);

    // Weighted average: Spending (30%), Saving (20%), Budgeting (30%), Consistency (20%)
    final totalScore = (spendingScore * 0.30) +
        (savingScore * 0.20) +
        (budgetScore * 0.30) +
        (consistencyScore * 0.20);

    return totalScore.round().clamp(0, 100);
  }

  static double _calculateSpendingScore(AppStateModel state) {
    if (state.totalIncome == 0) return 50.0;
    final spendingRatio = state.totalExpenses / state.totalIncome;
    if (spendingRatio <= 0.5) return 100.0;
    if (spendingRatio >= 1.0) return 20.0;
    return 100.0 - ((spendingRatio - 0.5) * 160);
  }

  static double _calculateSavingScore(AppStateModel state) {
    if (state.totalIncome == 0) return 50.0;
    final netSavings = state.totalIncome - state.totalExpenses;
    if (netSavings <= 0) return 10.0;
    final savingRate = netSavings / state.totalIncome;
    return (savingRate * 200).clamp(0.0, 100.0);
  }

  static double _calculateBudgetScore(AppStateModel state) {
    if (state.budgets.isEmpty) return 70.0;
    int withinLimit = 0;
    for (final b in state.budgets) {
      if (b.spent <= b.limit) withinLimit++;
    }
    return (withinLimit / state.budgets.length) * 100.0;
  }

  static double _calculateConsistencyScore(AppStateModel state) {
    if (state.transactions.length < 5) return 60.0;
    return 85.0; // Base active tracking score
  }

  static String getHealthStatusLabel(int score) {
    if (score >= 80) return 'Excellent Financial Health';
    if (score >= 60) return 'Good Financial Standing';
    if (score >= 40) return 'Fair - Needs Attention';
    return 'Critical - Budget Action Required';
  }
}
