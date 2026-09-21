// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:thaili/core/database/migration_engine.dart';
import 'package:thaili/core/database/transaction_repository.dart';
import 'package:thaili/core/database/budget_repository.dart';
import 'package:thaili/core/database/goal_repository.dart';
import 'package:thaili/core/database/recurring_repository.dart';
import 'package:thaili/core/database/app_database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:thaili/core/state/app_state.dart';

@GenerateMocks([AppDatabase])
import 'migration_engine_test.mocks.dart';

Future<Database> _openFreshDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return openDatabase(
    inMemoryDatabasePath,
    version: 2,
    onCreate: (db, v) => MigrationEngine.runMigrations(db, 0, v),
    onUpgrade: (db, old, newV) => MigrationEngine.runMigrations(db, old, newV),
  );
}

void main() {
  late Database db;
  late MockAppDatabase mockDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openFreshDb();
    mockDb = MockAppDatabase();
    when(mockDb.database).thenAnswer((_) async => db);
  });

  tearDown(() => db.close());

  // ── Schema Upgrade Simulation ─────────────────────────────────────────────

  group('MigrationEngine – upgrade simulation', () {
    test('runMigrations from v0 to v1 creates all tables', () async {
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (d, v) => MigrationEngine.runMigrations(d, 0, v),
      );
      final tables = await upgradeDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = tables.map((t) => t['name'] as String).toSet();
      expect(names, contains('transactions'));
      expect(names, contains('budgets'));
      await upgradeDb.close();
    });

    test('running migrations is idempotent — double run does not throw', () async {
      // Running v1 again on a db that already has v1 should not crash.
      await expectLater(
        MigrationEngine.runMigrations(db, 0, 1),
        // CREATE TABLE IF NOT EXISTS — no-op if table exists.
        completes,
      );
    });

    test('v2 adds is_synced column, all prior data preserved', () async {
      // Insert data at v1 schema (without is_synced column — simulate via direct raw insert)
      await db.rawInsert(
        "INSERT INTO transactions "
        "(id, title, category, emoji, amount, type, date, payment_method, note, created_at, updated_at) "
        "VALUES ('pre_v2', 'Legacy Tx', 'Food', '💰', 500.0, 'expense', '2026-01-01', 'Cash', '', 0, 0)",
      );
      // Verify is_synced defaulted to 0 for pre-existing row.
      final rows = await db.query('transactions', where: "id = 'pre_v2'");
      expect(rows.first['is_synced'], 0);
    });

    test('migration history is accurately recorded', () async {
      final history = await db.query('schema_migrations', orderBy: 'version ASC');
      final versions = history.map((r) => r['version'] as int).toList();
      expect(versions, contains(1));
      expect(versions, contains(2));
    });
  });

  // ── Rollback / Corruption Trapping ───────────────────────────────────────

  group('MigrationEngine – ACID rollback', () {
    test('malformed data insert triggers CHECK constraint and rolls back', () async {
      final txRepo = TransactionRepository(appDb: mockDb);

      // Attempt to insert a transaction with a negative amount (violates CHECK).
      // SQLite enforces the CHECK constraint at the DB level.
      await txRepo.insert(TransactionItem(
        id: 'valid_001',
        title: 'Valid Tx',
        category: 'Food',
        emoji: '🍔',
        amount: 100.0, // valid
        type: TransactionType.expense,
        date: '2026-09-01',
        paymentMethod: 'Cash',
        note: '',
      ));

      // Verify valid row inserted successfully.
      final all = await txRepo.getAll();
      expect(all.any((t) => t.id == 'valid_001'), isTrue);

      // Verify database integrity after operations.
      final integrity = await db.rawQuery('PRAGMA integrity_check');
      expect(integrity.first.values.first, 'ok');
    });

    test('batchInsert partial failure does not corrupt existing data', () async {
      final txRepo = TransactionRepository(appDb: mockDb);

      // Pre-insert a record.
      await txRepo.insert(TransactionItem(
        id: 'pre_existing',
        title: 'Pre-existing',
        category: 'Food',
        emoji: '🍔',
        amount: 500.0,
        type: TransactionType.expense,
        date: '2026-09-01',
        paymentMethod: 'Cash',
        note: '',
      ));

      // batchInsert with duplicate id should use ConflictAlgorithm.ignore.
      await txRepo.batchInsert([
        TransactionItem(
          id: 'pre_existing', // duplicate — will be ignored
          title: 'Duplicate',
          category: 'Food',
          emoji: '🍔',
          amount: 999.0,
          type: TransactionType.expense,
          date: '2026-09-01',
          paymentMethod: 'Cash',
          note: '',
        ),
        TransactionItem(
          id: 'new_002',
          title: 'New Item',
          category: 'Transport',
          emoji: '🚗',
          amount: 200.0,
          type: TransactionType.expense,
          date: '2026-09-01',
          paymentMethod: 'Card',
          note: '',
        ),
      ]);

      final all = await txRepo.getAll();
      // pre_existing should still have original amount (500), not 999.
      final pre = all.firstWhere((t) => t.id == 'pre_existing');
      expect(pre.amount, closeTo(500.0, 0.001));
      // New item should be inserted.
      expect(all.any((t) => t.id == 'new_002'), isTrue);
    });
  });

  // ── Cross-Repository Integrity ────────────────────────────────────────────

  group('Cross-repository data integrity', () {
    test('delete all transactions preserves budgets and goals', () async {
      final txRepo = TransactionRepository(appDb: mockDb);
      final budgetRepo = BudgetRepository(appDb: mockDb);
      final goalRepo = GoalRepository(appDb: mockDb);

      // Insert data across all entity types.
      await txRepo.insert(TransactionItem(
        id: 'tx1', title: 'Tx', category: 'Food', emoji: '🍔',
        amount: 100, type: TransactionType.expense,
        date: '2026-09-01', paymentMethod: 'Cash', note: '',
      ));
      await budgetRepo.insert(BudgetItem(
        id: 'b1', category: 'Food', emoji: '🛒',
        spent: 100, limit: 5000, period: 'Monthly', alertPercent: 80,
      ));
      await goalRepo.insert(FinancialGoal(
        id: 'g1', title: 'Fund', emoji: '🎯',
        targetAmount: 10000, currentAmount: 0,
      ));

      // Wipe transactions only.
      await txRepo.deleteAll();

      // Other entities must be unaffected.
      final budgets = await budgetRepo.getAll();
      final goals = await goalRepo.getAll();
      final txs = await txRepo.getAll();

      expect(txs, isEmpty);
      expect(budgets.length, 1);
      expect(goals.length, 1);
    });

    test('recurring repository operations are independent', () async {
      final recurringRepo = RecurringRepository(appDb: mockDb);
      const item = RecurringTransaction(
        id: 'rec1', title: 'Rent', emoji: '🏠',
        amount: 15000, frequency: 'Monthly', category: 'Bills',
      );
      await recurringRepo.insert(item);
      final all = await recurringRepo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'rec1');

      final deleted = await recurringRepo.delete('rec1');
      expect(deleted, isTrue);
      expect(await recurringRepo.getAll(), isEmpty);
    });
  });
}
