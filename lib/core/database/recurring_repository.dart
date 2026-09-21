import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../state/app_state.dart';
import 'app_database.dart';

/// Repository for [RecurringTransaction] persistence in the SQLite
/// `recurring_transactions` table.
class RecurringRepository {
  final AppDatabase _appDb;

  RecurringRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  // ── Mapping ────────────────────────────────────────────────────────────

  static RecurringTransaction _fromRow(Map<String, Object?> row) {
    return RecurringTransaction(
      id: row['id'] as String,
      title: row['title'] as String,
      emoji: row['emoji'] as String? ?? '🔄',
      amount: (row['amount'] as num).toDouble(),
      frequency: row['frequency'] as String? ?? 'Monthly',
      category: row['category'] as String? ?? 'Bills',
    );
  }

  static Map<String, Object?> _toRow(RecurringTransaction item) {
    return {
      'id': item.id,
      'title': item.title,
      'emoji': item.emoji,
      'amount': item.amount,
      'frequency': item.frequency,
      'category': item.category,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ── Read ────────────────────────────────────────────────────────────────

  Future<List<RecurringTransaction>> getAll() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(
        'recurring_transactions',
        orderBy: 'updated_at DESC',
      );
      return rows.map(_fromRow).toList();
    } catch (e, stack) {
      debugPrint('[RecurringRepository.getAll] Error: $e\n$stack');
      return [];
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> insert(RecurringTransaction item) async {
    final db = await _appDb.database;
    await db.insert(
      'recurring_transactions',
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<bool> delete(String id) async {
    final db = await _appDb.database;
    final count = await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<void> batchInsert(List<RecurringTransaction> items) async {
    if (items.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'recurring_transactions',
        _toRow(item),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await _appDb.database;
    await db.delete('recurring_transactions');
  }
}
