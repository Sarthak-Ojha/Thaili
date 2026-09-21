import 'package:flutter/foundation.dart';

/// Message contract for background isolate work requests.
class IsolateRequest {
  final String operation;
  final Map<String, dynamic> payload;

  const IsolateRequest({required this.operation, required this.payload});
}

/// Result returned from a background isolate operation.
class IsolateResult<T> {
  final T? data;
  final String? error;
  bool get hasError => error != null;

  const IsolateResult({this.data, this.error});
}

/// Offloads CPU-intensive data operations away from the Flutter Main / UI Isolate.
///
/// Flutter's `compute()` function spawns a fresh Dart isolate for each call,
/// executes the given top-level function, and returns the result via a
/// platform message — keeping frame rendering smooth at 60/120 FPS throughout.
///
/// Usage pattern:
/// ```dart
/// final totals = await DatabaseIsolateWorker.computeMonthlyTotals(transactions);
/// ```
///
/// Currently offloaded operations:
/// - `computeMonthlyTotals`   — folds 1,000+ transactions into monthly aggregates.
/// - `computeCategoryTotals`  — groups by category for analytics pie charts.
/// - `serializeForExport`     — encodes full JSON snapshot (used by BackupManager).
///
/// Design note: sqflite database operations themselves cannot be called inside
/// `compute()` because sqflite opens FFI connections tied to the originating
/// isolate. This worker handles the CPU-bound *processing* phase only.
/// The DB *read* is done first on the main isolate (sub-millisecond indexed
/// query), then the *computation* on the worker isolate.
class DatabaseIsolateWorker {
  DatabaseIsolateWorker._();

  // ── Monthly Income / Expense Aggregation ──────────────────────────────

  /// Computes monthly income and expense totals from a flat list of JSON maps.
  ///
  /// Returns a map keyed by `'YYYY-MM'`:
  /// ```json
  /// { "2026-09": { "income": 85000.0, "expense": 42000.0 } }
  /// ```
  static Future<Map<String, Map<String, double>>> computeMonthlyTotals(
    List<Map<String, dynamic>> txJsonList,
  ) {
    return compute(_computeMonthlyTotalsIsolate, txJsonList);
  }

  static Map<String, Map<String, double>> _computeMonthlyTotalsIsolate(
    List<Map<String, dynamic>> txJsonList,
  ) {
    final result = <String, Map<String, double>>{};
    for (final tx in txJsonList) {
      final rawDate = tx['date'] as String? ?? '';
      // Normalize to 'YYYY-MM' — date field is stored as ISO-8601 (YYYY-MM-DD).
      final monthKey = rawDate.length >= 7 ? rawDate.substring(0, 7) : rawDate;
      final amount = (tx['amount'] as num? ?? 0.0).toDouble();
      final type = tx['type'] as String? ?? 'expense';

      result.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0});
      result[monthKey]![type] = (result[monthKey]![type] ?? 0.0) + amount;
    }
    return result;
  }

  // ── Category Expense Totals ───────────────────────────────────────────

  /// Groups expenses by category and returns total per category,
  /// sorted descending. Powers the analytics pie chart.
  static Future<List<Map<String, dynamic>>> computeCategoryTotals(
    List<Map<String, dynamic>> txJsonList,
  ) {
    return compute(_computeCategoryTotalsIsolate, txJsonList);
  }

  static List<Map<String, dynamic>> _computeCategoryTotalsIsolate(
    List<Map<String, dynamic>> txJsonList,
  ) {
    final totals = <String, double>{};
    for (final tx in txJsonList) {
      if ((tx['type'] as String?) != 'expense') continue;
      final category = tx['category'] as String? ?? 'Other';
      final amount = (tx['amount'] as num? ?? 0.0).toDouble();
      totals[category] = (totals[category] ?? 0.0) + amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => {'category': e.key, 'total': e.value}).toList();
  }

  // ── JSON Export Serialization ─────────────────────────────────────────

  /// Serializes the complete application snapshot to a JSON string on a
  /// background isolate, preventing UI jank on large datasets.
  static Future<String> serializeForExport(
    Map<String, dynamic> appSnapshot,
  ) {
    return compute(_serializeForExportIsolate, appSnapshot);
  }

  static String _serializeForExportIsolate(Map<String, dynamic> snapshot) {
    // jsonEncode runs on the worker isolate — CPU-intensive for large lists.
    // ignore: avoid_dynamic_calls
    return _jsonEncodeSnapshot(snapshot);
  }

  static String _jsonEncodeSnapshot(Map<String, dynamic> snapshot) {
    // Manually construct JSON to avoid importing dart:convert in a way
    // that could block the main isolate.
    final buffer = StringBuffer('{');
    bool first = true;
    snapshot.forEach((key, value) {
      if (!first) buffer.write(',');
      buffer.write('"$key":');
      buffer.write(_encodeValue(value));
      first = false;
    });
    buffer.write('}');
    return buffer.toString();
  }

  static String _encodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return '[${value.map(_encodeValue).join(',')}]';
    }
    if (value is Map) {
      final parts = value.entries
          .map((e) => '"${e.key}":${_encodeValue(e.value)}')
          .join(',');
      return '{$parts}';
    }
    return '"${value.toString()}"';
  }

  // ── Batch Validation ─────────────────────────────────────────────────

  /// Validates a list of raw JSON maps before DB insertion.
  /// Returns validated entries and a list of error descriptions.
  static Future<({List<Map<String, dynamic>> valid, List<String> errors})>
      validateBatch(List<Map<String, dynamic>> rawItems) {
    return compute(_validateBatchIsolate, rawItems);
  }

  static ({List<Map<String, dynamic>> valid, List<String> errors})
      _validateBatchIsolate(List<Map<String, dynamic>> rawItems) {
    final valid = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (final item in rawItems) {
      final id = item['id'] as String?;
      final amount = item['amount'];
      final type = item['type'] as String?;

      if (id == null || id.isEmpty) {
        errors.add('Record missing id: $item');
        continue;
      }
      if (amount == null || (amount as num) < 0) {
        errors.add('Record id=$id has invalid amount: $amount');
        continue;
      }
      if (type == null || (type != 'income' && type != 'expense')) {
        errors.add('Record id=$id has invalid type: $type');
        continue;
      }
      valid.add(item);
    }

    return (valid: valid, errors: errors);
  }
}
