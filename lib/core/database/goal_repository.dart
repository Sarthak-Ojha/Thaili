import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../state/app_state.dart';
import 'app_database.dart';

/// Repository for [FinancialGoal] persistence in the SQLite `financial_goals` table.
class GoalRepository {
  final AppDatabase _appDb;

  GoalRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  // ── Mapping ────────────────────────────────────────────────────────────

  static FinancialGoal _fromRow(Map<String, Object?> row) {
    return FinancialGoal(
      id: row['id'] as String,
      title: row['title'] as String,
      emoji: row['emoji'] as String? ?? '🎯',
      targetAmount: (row['target_amount'] as num).toDouble(),
      currentAmount: (row['current_amount'] as num? ?? 0.0).toDouble(),
      estimatedCompletion:
          row['estimated_completion'] as String? ?? 'December 2026',
    );
  }

  static Map<String, Object?> _toRow(FinancialGoal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'emoji': goal.emoji,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'estimated_completion': goal.estimatedCompletion,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ── Read ────────────────────────────────────────────────────────────────

  Future<List<FinancialGoal>> getAll() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query('financial_goals', orderBy: 'updated_at DESC');
      return rows.map(_fromRow).toList();
    } catch (e, stack) {
      debugPrint('[GoalRepository.getAll] Error: $e\n$stack');
      return [];
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> insert(FinancialGoal goal) async {
    final db = await _appDb.database;
    await db.insert(
      'financial_goals',
      _toRow(goal),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<bool> update(FinancialGoal goal) async {
    final db = await _appDb.database;
    final count = await db.update(
      'financial_goals',
      _toRow(goal),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    return count > 0;
  }

  /// Upserts a goal: inserts if not present, updates if present.
  /// Used for the single-goal pattern in the current UI.
  Future<void> upsert(FinancialGoal goal) async {
    final db = await _appDb.database;
    await db.insert(
      'financial_goals',
      _toRow(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> delete(String id) async {
    final db = await _appDb.database;
    final count = await db.delete(
      'financial_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<void> batchInsert(List<FinancialGoal> goals) async {
    if (goals.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final goal in goals) {
      batch.insert(
        'financial_goals',
        _toRow(goal),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await _appDb.database;
    await db.delete('financial_goals');
  }
}
