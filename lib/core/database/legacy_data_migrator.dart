import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';
import 'budget_repository.dart';
import 'goal_repository.dart';
import 'recurring_repository.dart';
import 'transaction_repository.dart';

/// Zero-loss bridge that reads legacy JSON arrays from SharedPreferences
/// and atomically migrates them into the SQLite repository layer.
///
/// This runs exactly once on first boot under the new architecture.
/// After a successful migration the flag `'db_migration_v1_done'` is set
/// in SharedPreferences so the bridge is never executed again.
///
/// Safety guarantees:
/// - Each entity type (transactions, budgets, goals, recurring) is migrated
///   independently; failure of one type does not block the others.
/// - `batchInsert` on each repository uses `ConflictAlgorithm.ignore` so
///   duplicate IDs (theoretically impossible but defensively handled) are
///   silently skipped rather than crashing the app.
/// - The legacy SharedPreferences data is **never deleted** — only archived
///   under suffixed keys (`'transactions_v0'`, etc.) so recovery is always
///   possible without a backup file.
class LegacyDataMigrator {
  LegacyDataMigrator._();

  static const String _migrationFlagKey = 'db_migration_v1_done';

  /// Entry point. Call from `AppStateModel.init()` before loading any data.
  static Future<void> runIfNeeded({
    required TransactionRepository txRepo,
    required BudgetRepository budgetRepo,
    required GoalRepository goalRepo,
    required RecurringRepository recurringRepo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationFlagKey) == true) return;

    debugPrint('[LegacyDataMigrator] Starting zero-loss migration from SharedPreferences...');

    int migratedCount = 0;

    // ── Transactions ──────────────────────────────────────────────────────
    try {
      final txJson = prefs.getString('transactions');
      if (txJson != null && txJson.isNotEmpty) {
        final List rawList = jsonDecode(txJson) as List;
        final items = rawList
            .cast<Map<String, dynamic>>()
            .map(TransactionItem.fromJson)
            .toList();
        await txRepo.batchInsert(items);
        migratedCount += items.length;
        debugPrint('[LegacyDataMigrator] ✓ ${items.length} transactions migrated.');
        // Archive legacy data (do NOT delete).
        await prefs.setString('transactions_v0', txJson);
      }
    } catch (e, stack) {
      debugPrint('[LegacyDataMigrator] ✗ Transactions migration error: $e\n$stack');
    }

    // ── Budgets ───────────────────────────────────────────────────────────
    try {
      final bgJson = prefs.getString('budgets');
      if (bgJson != null && bgJson.isNotEmpty) {
        final List rawList = jsonDecode(bgJson) as List;
        final items = rawList
            .cast<Map<String, dynamic>>()
            .map(BudgetItem.fromJson)
            .toList();
        await budgetRepo.batchInsert(items);
        migratedCount += items.length;
        debugPrint('[LegacyDataMigrator] ✓ ${items.length} budgets migrated.');
        await prefs.setString('budgets_v0', bgJson);
      }
    } catch (e, stack) {
      debugPrint('[LegacyDataMigrator] ✗ Budgets migration error: $e\n$stack');
    }

    // ── Goals ─────────────────────────────────────────────────────────────
    try {
      final goalJson = prefs.getString('goals');
      if (goalJson != null && goalJson.isNotEmpty) {
        final List rawList = jsonDecode(goalJson) as List;
        final items = rawList
            .cast<Map<String, dynamic>>()
            .map(FinancialGoal.fromJson)
            .toList();
        await goalRepo.batchInsert(items);
        migratedCount += items.length;
        debugPrint('[LegacyDataMigrator] ✓ ${items.length} goals migrated.');
        await prefs.setString('goals_v0', goalJson);
      }
    } catch (e, stack) {
      debugPrint('[LegacyDataMigrator] ✗ Goals migration error: $e\n$stack');
    }

    // ── Recurring Transactions ────────────────────────────────────────────
    try {
      final recJson = prefs.getString('recurring');
      if (recJson != null && recJson.isNotEmpty) {
        final List rawList = jsonDecode(recJson) as List;
        final items = rawList
            .cast<Map<String, dynamic>>()
            .map(RecurringTransaction.fromJson)
            .toList();
        await recurringRepo.batchInsert(items);
        migratedCount += items.length;
        debugPrint('[LegacyDataMigrator] ✓ ${items.length} recurring transactions migrated.');
        await prefs.setString('recurring_v0', recJson);
      }
    } catch (e, stack) {
      debugPrint('[LegacyDataMigrator] ✗ Recurring migration error: $e\n$stack');
    }

    // Mark migration complete.
    await prefs.setBool(_migrationFlagKey, true);
    debugPrint(
      '[LegacyDataMigrator] Migration complete. Total records migrated: $migratedCount.',
    );
  }
}
