import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/core/state/app_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  // --------------------------------------------------------------------------
  // TransactionItem JSON round-trip
  // --------------------------------------------------------------------------
  group('TransactionItem – JSON serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = makeTransaction(
        id: 'tx_json_1',
        title: 'Coffee',
        category: 'Food & Dining',
        emoji: '☕',
        amount: 250.0,
        type: TransactionType.expense,
        date: '2026-09-01',
        paymentMethod: 'Card',
        note: 'Morning brew',
      );

      final json = original.toJson();
      final restored = TransactionItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.emoji, original.emoji);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.date, original.date);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.note, original.note);
    });

    test('fromJson handles income type correctly', () {
      final tx = makeTransaction(type: TransactionType.income);
      final restored = TransactionItem.fromJson(tx.toJson());
      expect(restored.type, TransactionType.income);
    });

    test('fromJson defaults missing fields gracefully', () {
      final json = <String, dynamic>{'id': 'minimal'};
      final tx = TransactionItem.fromJson(json);
      expect(tx.id, 'minimal');
      expect(tx.title, '');
      expect(tx.category, '');
      expect(tx.emoji, '💰');
      expect(tx.amount, 0.0);
      expect(tx.type, TransactionType.expense);
      expect(tx.paymentMethod, 'Cash');
      expect(tx.note, '');
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'title': null,
        'amount': null,
        'type': null,
      };
      final tx = TransactionItem.fromJson(json);
      expect(tx.id, '');
      expect(tx.title, '');
      expect(tx.amount, 0.0);
      expect(tx.type, TransactionType.expense);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = makeTransaction(id: 'orig', amount: 100.0);
      final copy = original.copyWith(amount: 500.0, title: 'Updated');
      expect(copy.id, 'orig');
      expect(copy.amount, 500.0);
      expect(copy.title, 'Updated');
      // Original is unchanged
      expect(original.amount, 100.0);
    });
  });

  // --------------------------------------------------------------------------
  // BudgetItem JSON round-trip
  // --------------------------------------------------------------------------
  group('BudgetItem – JSON serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = makeBudget(
        id: 'b_json_1',
        category: 'Transport',
        emoji: '🚗',
        spent: 300.0,
        limit: 800.0,
        period: 'Weekly',
        alertPercent: 75,
      );

      final json = original.toJson();
      final restored = BudgetItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.emoji, original.emoji);
      expect(restored.spent, original.spent);
      expect(restored.limit, original.limit);
      expect(restored.period, original.period);
      expect(restored.alertPercent, original.alertPercent);
    });

    test('fromJson defaults missing fields gracefully', () {
      final json = <String, dynamic>{'id': 'minimal_b'};
      final b = BudgetItem.fromJson(json);
      expect(b.id, 'minimal_b');
      expect(b.category, '');
      expect(b.emoji, '📁');
      expect(b.spent, 0.0);
      expect(b.limit, 0.0);
      expect(b.period, 'Monthly');
      expect(b.alertPercent, 80);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'spent': null,
        'limit': null,
        'alertPercent': null,
      };
      final b = BudgetItem.fromJson(json);
      expect(b.id, '');
      expect(b.spent, 0.0);
      expect(b.limit, 0.0);
      expect(b.alertPercent, 80);
    });
  });

  // --------------------------------------------------------------------------
  // FinancialGoal JSON round-trip
  // --------------------------------------------------------------------------
  group('FinancialGoal – JSON serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = makeGoal(
        id: 'g_json_1',
        title: 'New Car',
        emoji: '🚙',
        targetAmount: 500000.0,
        currentAmount: 125000.0,
        estimatedCompletion: 'December 2028',
      );

      final json = original.toJson();
      final restored = FinancialGoal.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.emoji, original.emoji);
      expect(restored.targetAmount, original.targetAmount);
      expect(restored.currentAmount, original.currentAmount);
      expect(restored.estimatedCompletion, original.estimatedCompletion);
    });

    test('fromJson defaults missing fields gracefully', () {
      final json = <String, dynamic>{'id': 'minimal_g'};
      final g = FinancialGoal.fromJson(json);
      expect(g.id, 'minimal_g');
      expect(g.title, '');
      expect(g.emoji, '🎯');
      expect(g.targetAmount, 0.0);
      expect(g.currentAmount, 0.0);
      expect(g.estimatedCompletion, 'December 2026');
    });

    test('fromJson handles null numeric values with 0.0 default', () {
      final json = <String, dynamic>{
        'id': 'g_null',
        'targetAmount': null,
        'currentAmount': null,
      };
      final g = FinancialGoal.fromJson(json);
      expect(g.targetAmount, 0.0);
      expect(g.currentAmount, 0.0);
    });
  });

  // --------------------------------------------------------------------------
  // RecurringTransaction JSON round-trip
  // --------------------------------------------------------------------------
  group('RecurringTransaction – JSON serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = makeRecurring(
        id: 'r_json_1',
        title: 'Netflix',
        emoji: '📺',
        amount: 599.0,
        frequency: 'Monthly',
        category: 'Entertainment',
      );

      final json = original.toJson();
      final restored = RecurringTransaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.emoji, original.emoji);
      expect(restored.amount, original.amount);
      expect(restored.frequency, original.frequency);
      expect(restored.category, original.category);
    });

    test('fromJson defaults missing fields gracefully', () {
      final json = <String, dynamic>{'id': 'min_r'};
      final r = RecurringTransaction.fromJson(json);
      expect(r.id, 'min_r');
      expect(r.title, '');
      expect(r.emoji, '🔄');
      expect(r.amount, 0.0);
      expect(r.frequency, 'Monthly');
      expect(r.category, 'Bills');
    });
  });
}
