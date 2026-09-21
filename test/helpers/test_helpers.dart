import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/state/app_state.dart';

// ---------------------------------------------------------------------------
// SharedPreferences mock setup
// ---------------------------------------------------------------------------

/// Call in setUp() to prevent real SharedPreferences I/O in tests.
Future<void> setupMockPrefs([Map<String, Object>? initialValues]) async {
  SharedPreferences.setMockInitialValues(initialValues ?? {});
}

// ---------------------------------------------------------------------------
// Singleton reset
// ---------------------------------------------------------------------------

/// Resets the AppStateModel singleton and clears SharedPreferences mock.
Future<void> resetState() async {
  SharedPreferences.setMockInitialValues({});
  AppStateModel.enablePersistence = false;
  AppStateModel().resetForTesting();
}

// ---------------------------------------------------------------------------
// Model factories
// ---------------------------------------------------------------------------

TransactionItem makeTransaction({
  String id = 'tx_test_001',
  String title = 'Test Transaction',
  String category = 'Food & Dining',
  String emoji = '🍔',
  double amount = 500.0,
  TransactionType type = TransactionType.expense,
  String date = '2026-09-01',
  String paymentMethod = 'Cash',
  String note = '',
}) {
  return TransactionItem(
    id: id,
    title: title,
    category: category,
    emoji: emoji,
    amount: amount,
    type: type,
    date: date,
    paymentMethod: paymentMethod,
    note: note,
  );
}

BudgetItem makeBudget({
  String id = 'b_test_001',
  String category = 'Groceries',
  String emoji = '🛒',
  double spent = 200.0,
  double limit = 500.0,
  String period = 'Monthly',
  int alertPercent = 80,
}) {
  return BudgetItem(
    id: id,
    category: category,
    emoji: emoji,
    spent: spent,
    limit: limit,
    period: period,
    alertPercent: alertPercent,
  );
}

FinancialGoal makeGoal({
  String id = 'g_test_001',
  String title = 'Test Goal',
  String emoji = '🎯',
  double targetAmount = 10000.0,
  double currentAmount = 2500.0,
  String estimatedCompletion = 'September 2027',
}) {
  return FinancialGoal(
    id: id,
    title: title,
    emoji: emoji,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    estimatedCompletion: estimatedCompletion,
  );
}

RecurringTransaction makeRecurring({
  String id = 'rec_test_001',
  String title = 'Monthly Rent',
  String emoji = '🏠',
  double amount = 15000.0,
  String frequency = 'Monthly',
  String category = 'Bills',
}) {
  return RecurringTransaction(
    id: id,
    title: title,
    emoji: emoji,
    amount: amount,
    frequency: frequency,
    category: category,
  );
}

// ---------------------------------------------------------------------------
// Widget test helpers
// ---------------------------------------------------------------------------

Widget testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}
