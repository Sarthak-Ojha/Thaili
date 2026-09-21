import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// A registered migration step.
class _Migration {
  final int version;
  final String name;
  final Future<void> Function(DatabaseExecutor db) up;

  const _Migration({required this.version, required this.name, required this.up});
}

/// Automated, transactional SQLite schema migration engine.
///
/// Each migration runs inside a `BEGIN TRANSACTION … COMMIT` block.
/// If the migration throws, the transaction is rolled back automatically
/// so user data is never left in a partial / corrupt state.
///
/// Migrations are additive — running them multiple times is idempotent.
/// New versions are simply appended to [_migrations]; the engine detects
/// the current `user_version` PRAGMA and applies only the pending steps.
class MigrationEngine {
  MigrationEngine._();

  // ── Migration Registry ─────────────────────────────────────────────────
  // Add new migrations here in monotonically increasing version order.
  static final List<_Migration> _migrations = [
    _Migration(
      version: 1,
      name: 'initial_schema',
      up: _v1InitialSchema,
    ),
    _Migration(
      version: 2,
      name: 'add_sync_tracking',
      up: _v2AddSyncTracking,
    ),
  ];

  /// Runs all pending migrations from [currentVersion] to [targetVersion].
  ///
  /// Each step executes atomically inside a transaction. Any exception
  /// causes the current migration to roll back, protecting existing data.
  static Future<void> runMigrations(
    Database db,
    int currentVersion,
    int targetVersion,
  ) async {
    final pending = _migrations
        .where((m) => m.version > currentVersion && m.version <= targetVersion)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in pending) {
      debugPrint('[MigrationEngine] Applying v${migration.version}: ${migration.name}');
      try {
        await db.transaction((txn) async {
          await migration.up(txn);
          // Record migration in history table (replace on idempotent rerun).
          await txn.insert(
            'schema_migrations',
            {
              'version': migration.version,
              'name': migration.name,
              'applied_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
        debugPrint('[MigrationEngine] ✓ v${migration.version} applied.');
      } catch (e, stack) {
        // Transaction is automatically rolled back on exception by sqflite.
        debugPrint('[MigrationEngine] ✗ v${migration.version} FAILED — rolled back.\n$e\n$stack');
        rethrow;
      }
    }
  }

  // ── v1: Initial Schema ──────────────────────────────────────────────────

  static Future<void> _v1InitialSchema(DatabaseExecutor db) async {
    // Migration history bookkeeping table (created first so later migrations
    // can insert records into it).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version     INTEGER PRIMARY KEY NOT NULL,
        name        TEXT    NOT NULL,
        applied_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id              TEXT    PRIMARY KEY NOT NULL,
        title           TEXT    NOT NULL,
        category        TEXT    NOT NULL,
        emoji           TEXT    NOT NULL DEFAULT '💰',
        amount          REAL    NOT NULL CHECK(amount > 0),
        type            TEXT    NOT NULL CHECK(type IN ('income','expense')),
        date            TEXT    NOT NULL,
        payment_method  TEXT    NOT NULL DEFAULT 'Cash',
        note            TEXT    NOT NULL DEFAULT '',
        created_at      INTEGER NOT NULL,
        updated_at      INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id              TEXT    PRIMARY KEY NOT NULL,
        category        TEXT    NOT NULL UNIQUE,
        emoji           TEXT    NOT NULL DEFAULT '📁',
        spent           REAL    NOT NULL DEFAULT 0.0,
        limit_amount    REAL    NOT NULL CHECK(limit_amount > 0),
        period          TEXT    NOT NULL DEFAULT 'Monthly',
        alert_percent   INTEGER NOT NULL DEFAULT 80,
        updated_at      INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_goals (
        id                    TEXT  PRIMARY KEY NOT NULL,
        title                 TEXT  NOT NULL,
        emoji                 TEXT  NOT NULL DEFAULT '🎯',
        target_amount         REAL  NOT NULL CHECK(target_amount > 0),
        current_amount        REAL  NOT NULL DEFAULT 0.0,
        estimated_completion  TEXT  NOT NULL DEFAULT 'December 2026',
        updated_at            INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions (
        id          TEXT    PRIMARY KEY NOT NULL,
        title       TEXT    NOT NULL,
        emoji       TEXT    NOT NULL DEFAULT '🔄',
        amount      REAL    NOT NULL CHECK(amount > 0),
        frequency   TEXT    NOT NULL DEFAULT 'Monthly',
        category    TEXT    NOT NULL DEFAULT 'Bills',
        updated_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key         TEXT    PRIMARY KEY NOT NULL,
        value       TEXT    NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── Indexes for common query patterns ──────────────────────────────
    // Timeline pagination, date-range filters (most common query).
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions(date DESC)');
    // Category expense breakdown for budget recalculation.
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_category_date ON transactions(category, date DESC)');
    // Income vs expense aggregation for analytics.
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_type_date ON transactions(type, date DESC)');
    // Fast budget threshold lookup.
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_category ON budgets(category)');
  }

  // ── v2: Add Sync Tracking Column ────────────────────────────────────────

  static Future<void> _v2AddSyncTracking(DatabaseExecutor db) async {
    // SQLite does not support adding columns with constraints in ALTER TABLE,
    // so we use a default value of 0 (unsynced) for backward compatibility.
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
    );
  }
}
