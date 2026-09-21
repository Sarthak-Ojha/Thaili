import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../state/app_state.dart';
import 'app_database.dart';

/// Repository for [BudgetItem] persistence in the SQLite `budgets` table.
class BudgetRepository {
  final AppDatabase _appDb;

  BudgetRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  // ── Mapping ────────────────────────────────────────────────────────────

  static BudgetItem _fromRow(Map<String, Object?> row) {
    return BudgetItem(
      id: row['id'] as String,
      category: row['category'] as String,
      emoji: row['emoji'] as String? ?? '📁',
      spent: (row['spent'] as num? ?? 0.0).toDouble(),
      limit: (row['limit_amount'] as num).toDouble(),
      period: row['period'] as String? ?? 'Monthly',
      alertPercent: (row['alert_percent'] as num? ?? 80).toInt(),
    );
  }

  static Map<String, Object?> _toRow(BudgetItem item) {
    return {
      'id': item.id,
      'category': item.category,
      'emoji': item.emoji,
      'spent': item.spent,
      'limit_amount': item.limit,
      'period': item.period,
      'alert_percent': item.alertPercent,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ── Read ────────────────────────────────────────────────────────────────

  Future<List<BudgetItem>> getAll() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query('budgets', orderBy: 'category ASC');
      return rows.map(_fromRow).toList();
    } catch (e, stack) {
      debugPrint('[BudgetRepository.getAll] Error: $e\n$stack');
      return [];
    }
  }

  Future<BudgetItem?> getByCategory(String category) async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(
        'budgets',
        where: 'category = ?',
        whereArgs: [category],
        limit: 1,
      );
      return rows.isEmpty ? null : _fromRow(rows.first);
    } catch (e) {
      debugPrint('[BudgetRepository.getByCategory] Error: $e');
      return null;
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> insert(BudgetItem item) async {
    final db = await _appDb.database;
    await db.insert(
      'budgets',
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<bool> update(BudgetItem item) async {
    final db = await _appDb.database;
    final count = await db.update(
      'budgets',
      _toRow(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return count > 0;
  }

  Future<bool> delete(String id) async {
    final db = await _appDb.database;
    final count = await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Updates the `spent` field for [category] based on the total
  /// expense sum from the transactions table. Called after every expense
  /// mutation to keep budget tracking in sync.
  Future<void> recalculateSpent(String category, double totalSpent) async {
    try {
      final db = await _appDb.database;
      await db.update(
        'budgets',
        {
          'spent': totalSpent,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'category = ?',
        whereArgs: [category],
      );
    } catch (e) {
      debugPrint('[BudgetRepository.recalculateSpent] Error: $e');
    }
  }

  Future<void> batchInsert(List<BudgetItem> items) async {
    if (items.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'budgets',
        _toRow(item),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await _appDb.database;
    await db.delete('budgets');
  }
}
