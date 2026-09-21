// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:thaili/core/isolates/database_isolate_worker.dart';

void main() {
  // ── computeMonthlyTotals ──────────────────────────────────────────────────

  group('DatabaseIsolateWorker.computeMonthlyTotals', () {
    test('correctly aggregates income and expense by month', () async {
      final txList = [
        {'id': '1', 'date': '2026-09-01', 'amount': 50000.0, 'type': 'income'},
        {'id': '2', 'date': '2026-09-15', 'amount': 20000.0, 'type': 'expense'},
        {'id': '3', 'date': '2026-10-01', 'amount': 15000.0, 'type': 'expense'},
      ];

      final result = await DatabaseIsolateWorker.computeMonthlyTotals(txList);

      expect(result.containsKey('2026-09'), isTrue);
      expect(result.containsKey('2026-10'), isTrue);
      expect(result['2026-09']!['income'], closeTo(50000.0, 0.001));
      expect(result['2026-09']!['expense'], closeTo(20000.0, 0.001));
      expect(result['2026-10']!['expense'], closeTo(15000.0, 0.001));
    });

    test('returns empty map for empty input', () async {
      final result = await DatabaseIsolateWorker.computeMonthlyTotals([]);
      expect(result, isEmpty);
    });

    test('handles missing date field gracefully', () async {
      final txList = [
        {'id': '1', 'amount': 100.0, 'type': 'expense'}, // no date
      ];
      final result = await DatabaseIsolateWorker.computeMonthlyTotals(txList);
      // Should complete without throwing; date key will be empty string.
      expect(result, isNotEmpty);
    });

    test('accumulates multiple transactions in the same month', () async {
      final txList = List.generate(
        100,
        (i) => {
          'id': 'tx$i',
          'date': '2026-09-${(i % 30 + 1).toString().padLeft(2, '0')}',
          'amount': 100.0,
          'type': 'expense',
        },
      );
      final result = await DatabaseIsolateWorker.computeMonthlyTotals(txList);
      expect(result['2026-09']!['expense'], closeTo(10000.0, 0.001));
    });
  });

  // ── computeCategoryTotals ─────────────────────────────────────────────────

  group('DatabaseIsolateWorker.computeCategoryTotals', () {
    test('groups expenses by category, sorted descending', () async {
      final txList = [
        {'id': '1', 'amount': 500.0, 'type': 'expense', 'category': 'Food'},
        {'id': '2', 'amount': 300.0, 'type': 'expense', 'category': 'Transport'},
        {'id': '3', 'amount': 1000.0, 'type': 'expense', 'category': 'Food'},
        {'id': '4', 'amount': 200.0, 'type': 'income', 'category': 'Salary'},
      ];

      final result = await DatabaseIsolateWorker.computeCategoryTotals(txList);

      // Income should be excluded.
      expect(result.any((r) => r['category'] == 'Salary'), isFalse);
      // Food (1500) should be first, Transport (300) second.
      expect(result[0]['category'], 'Food');
      expect(result[0]['total'], closeTo(1500.0, 0.001));
      expect(result[1]['category'], 'Transport');
    });

    test('returns empty list for all-income transactions', () async {
      final txList = [
        {'id': '1', 'amount': 5000.0, 'type': 'income', 'category': 'Salary'},
      ];
      final result = await DatabaseIsolateWorker.computeCategoryTotals(txList);
      expect(result, isEmpty);
    });

    test('returns empty list for empty input', () async {
      final result = await DatabaseIsolateWorker.computeCategoryTotals([]);
      expect(result, isEmpty);
    });
  });

  // ── validateBatch ─────────────────────────────────────────────────────────

  group('DatabaseIsolateWorker.validateBatch', () {
    test('accepts valid records', () async {
      final input = [
        {'id': 'v1', 'amount': 100.0, 'type': 'expense'},
        {'id': 'v2', 'amount': 0.0, 'type': 'income'},
      ];
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch(input);
      expect(valid.length, 2);
      expect(errors, isEmpty);
    });

    test('rejects records with missing id', () async {
      final input = [
        {'amount': 100.0, 'type': 'expense'}, // no id
      ];
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch(input);
      expect(valid, isEmpty);
      expect(errors.length, 1);
      expect(errors.first, contains('missing id'));
    });

    test('rejects records with negative amount', () async {
      final input = [
        {'id': 'neg1', 'amount': -50.0, 'type': 'expense'},
      ];
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch(input);
      expect(valid, isEmpty);
      expect(errors.first, contains('invalid amount'));
    });

    test('rejects records with invalid type', () async {
      final input = [
        {'id': 'bad_type', 'amount': 100.0, 'type': 'payment'}, // not income/expense
      ];
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch(input);
      expect(valid, isEmpty);
      expect(errors.first, contains('invalid type'));
    });

    test('separates valid and invalid records in mixed batch', () async {
      final input = [
        {'id': 'good', 'amount': 100.0, 'type': 'expense'},
        {'id': 'bad', 'amount': -1.0, 'type': 'expense'},
        {'amount': 500.0, 'type': 'income'}, // missing id
      ];
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch(input);
      expect(valid.length, 1);
      expect(errors.length, 2);
    });

    test('handles empty input', () async {
      final (:valid, :errors) = await DatabaseIsolateWorker.validateBatch([]);
      expect(valid, isEmpty);
      expect(errors, isEmpty);
    });
  });

  // ── serializeForExport ────────────────────────────────────────────────────

  group('DatabaseIsolateWorker.serializeForExport', () {
    test('serializes snapshot to valid JSON-like string', () async {
      final snapshot = {
        'version': 1,
        'balance': 50000.0,
        'transactions': [
          {'id': 'tx1', 'amount': 500.0},
        ],
      };
      final result = await DatabaseIsolateWorker.serializeForExport(snapshot);
      expect(result, isNotEmpty);
      expect(result, contains('version'));
      expect(result, contains('balance'));
    });

    test('handles empty snapshot', () async {
      final result = await DatabaseIsolateWorker.serializeForExport({});
      expect(result, '{}');
    });

    test('handles nested maps and lists', () async {
      final snapshot = {
        'list': [1, 2, 3],
        'nested': {'key': 'value'},
        'bool_val': true,
        'null_val': null,
      };
      final result = await DatabaseIsolateWorker.serializeForExport(snapshot);
      expect(result, isNotEmpty);
      expect(result, contains('"list"'));
      expect(result, contains('"nested"'));
    });
  });
}
