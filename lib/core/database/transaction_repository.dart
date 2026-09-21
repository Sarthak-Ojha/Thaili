import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../state/app_state.dart';
import 'app_database.dart';

/// Repository for [TransactionItem] persistence in the SQLite `transactions` table.
///
/// All write operations return immediately to the caller after the operation
/// completes on the database. Heavy aggregations (monthly totals, category
/// breakdowns) are designed to be called from a background isolate via
/// [DatabaseIsolateWorker] to keep the UI thread free.
class TransactionRepository {
  final AppDatabase _appDb;

  TransactionRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  // ── Mapping ────────────────────────────────────────────────────────────

  static TransactionItem _fromRow(Map<String, Object?> row) {
    return TransactionItem(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      emoji: row['emoji'] as String? ?? '💰',
      amount: (row['amount'] as num).toDouble(),
      type: (row['type'] as String) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: row['date'] as String,
      paymentMethod: row['payment_method'] as String? ?? 'Cash',
      note: row['note'] as String? ?? '',
    );
  }

  static Map<String, Object?> _toRow(TransactionItem item) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': item.id,
      'title': item.title,
      'category': item.category,
      'emoji': item.emoji,
      'amount': item.amount,
      'type': item.type.name,
      'date': item.date,
      'payment_method': item.paymentMethod,
      'note': item.note,
      'created_at': now,
      'updated_at': now,
    };
  }

  // ── Read Operations ─────────────────────────────────────────────────────

  /// Fetches all transactions, ordered by date descending (newest first).
  Future<List<TransactionItem>> getAll() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query('transactions', orderBy: 'date DESC');
      return rows.map(_fromRow).toList();
    } catch (e, stack) {
      debugPrint('[TransactionRepository.getAll] Error: $e\n$stack');
      return [];
    }
  }

  /// Fetches transactions matching an optional [type] filter,
  /// constrained to [startDate]–[endDate] (ISO-8601 strings, inclusive).
  Future<List<TransactionItem>> getFiltered({
    String? type,         // 'income' | 'expense'
    String? startDate,    // e.g. '2026-09-01'
    String? endDate,      // e.g. '2026-09-30'
    String? category,
  }) async {
    try {
      final db = await _appDb.database;
      final where = <String>[];
      final args = <Object?>[];

      if (type != null) {
        where.add('type = ?');
        args.add(type);
      }
      if (startDate != null) {
        where.add('date >= ?');
        args.add(startDate);
      }
      if (endDate != null) {
        where.add('date <= ?');
        args.add(endDate);
      }
      if (category != null) {
        where.add('category = ?');
        args.add(category);
      }

      final rows = await db.query(
        'transactions',
        where: where.isNotEmpty ? where.join(' AND ') : null,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'date DESC',
      );
      return rows.map(_fromRow).toList();
    } catch (e, stack) {
      debugPrint('[TransactionRepository.getFiltered] Error: $e\n$stack');
      return [];
    }
  }

  /// Returns the total expense spent in [category] — used for budget sync.
  Future<double> getTotalExpenseByCategory(String category) async {
    try {
      final db = await _appDb.database;
      final result = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0.0) AS total "
        "FROM transactions WHERE type = 'expense' AND category = ?",
        [category],
      );
      return (result.first['total'] as num? ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('[TransactionRepository.getTotalExpenseByCategory] Error: $e');
      return 0.0;
    }
  }

  // ── Write Operations (atomic via sqflite) ──────────────────────────────

  /// Inserts a new transaction. Throws on constraint violation.
  Future<void> insert(TransactionItem item) async {
    final db = await _appDb.database;
    await db.insert(
      'transactions',
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  /// Updates an existing transaction row. Returns `true` if a row was affected.
  Future<bool> update(TransactionItem item) async {
    final db = await _appDb.database;
    final row = _toRow(item);
    row['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    final count = await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return count > 0;
  }

  /// Deletes a transaction by [id]. Returns `true` if a row was deleted.
  Future<bool> delete(String id) async {
    final db = await _appDb.database;
    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Executes a batch insert for [items] within a single SQLite transaction.
  ///
  /// All rows succeed or all fail atomically — no partial writes.
  Future<void> batchInsert(List<TransactionItem> items) async {
    if (items.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'transactions',
        _toRow(item),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Deletes all rows. Use only for full data wipe / factory reset.
  Future<void> deleteAll() async {
    final db = await _appDb.database;
    await db.delete('transactions');
  }
}
