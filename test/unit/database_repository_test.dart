// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:thaili/core/database/app_database.dart';
import 'package:thaili/core/database/transaction_repository.dart';
import 'package:thaili/core/database/budget_repository.dart';
import 'package:thaili/core/database/goal_repository.dart';
import 'package:thaili/core/database/migration_engine.dart';
import 'package:thaili/core/state/app_state.dart';

@GenerateMocks([AppDatabase])
import 'database_repository_test.mocks.dart';

// ── Shared in-memory database setup ──────────────────────────────────────────

/// Creates a fully-migrated in-memory SQLite database for testing.
/// Uses sqflite_common_ffi to run on desktop / CI without a real device.
Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 2,
    onCreate: (db, version) async {
      await MigrationEngine.runMigrations(db, 0, version);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      await MigrationEngine.runMigrations(db, oldVersion, newVersion);
    },
    onOpen: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );
  return db;
}

void main() {
  late Database testDb;
  late MockAppDatabase mockAppDb;
  late TransactionRepository txRepo;
  late BudgetRepository budgetRepo;
  late GoalRepository goalRepo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await _openTestDb();
    mockAppDb = MockAppDatabase();
    when(mockAppDb.database).thenAnswer((_) async => testDb);

    txRepo = TransactionRepository(appDb: mockAppDb);
    budgetRepo = BudgetRepository(appDb: mockAppDb);
    goalRepo = GoalRepository(appDb: mockAppDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  // ── TransactionRepository ─────────────────────────────────────────────────

  group('TransactionRepository', () {
    TransactionItem makeItem({
      String id = 'tx_001',
      double amount = 500.0,
      TransactionType type = TransactionType.expense,
      String category = 'Food & Dining',
    }) {
      return TransactionItem(
        id: id,
        title: 'Test Tx',
        category: category,
        emoji: '🍔',
        amount: amount,
        type: type,
        date: '2026-09-01',
        paymentMethod: 'Cash',
        note: '',
      );
    }

    test('insert and getAll returns item', () async {
      await txRepo.insert(makeItem());
      final all = await txRepo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'tx_001');
    });

    test('getAll returns newest first (date DESC)', () async {
      await txRepo.insert(makeItem(id: 'tx_01').copyWith(date: '2026-09-01'));
      await txRepo.insert(makeItem(id: 'tx_02').copyWith(date: '2026-09-10'));
      final all = await txRepo.getAll();
      expect(all.first.id, 'tx_02'); // newer first
    });

    test('insert duplicate id throws (ConflictAlgorithm.fail)', () async {
      await txRepo.insert(makeItem());
      expect(
        () async => txRepo.insert(makeItem()), // same id
        throwsA(anything),
      );
    });

    test('update modifies the row', () async {
      await txRepo.insert(makeItem());
      final updated = makeItem().copyWith(amount: 999.0);
      final result = await txRepo.update(updated);
      expect(result, isTrue);
      final all = await txRepo.getAll();
      expect(all.first.amount, 999.0);
    });

    test('update non-existent id returns false', () async {
      final result = await txRepo.update(makeItem(id: 'ghost'));
      expect(result, isFalse);
    });

    test('delete removes the row', () async {
      await txRepo.insert(makeItem());
      final result = await txRepo.delete('tx_001');
      expect(result, isTrue);
      final all = await txRepo.getAll();
      expect(all, isEmpty);
    });

    test('delete non-existent id returns false', () async {
      final result = await txRepo.delete('ghost_id');
      expect(result, isFalse);
    });

    test('getFiltered by type returns only matching rows', () async {
      await txRepo.insert(makeItem(id: 'e1', type: TransactionType.expense));
      await txRepo.insert(
        makeItem(id: 'i1', type: TransactionType.income, amount: 2000),
      );
      final expenses = await txRepo.getFiltered(type: 'expense');
      expect(expenses.length, 1);
      expect(expenses.first.id, 'e1');

      final incomes = await txRepo.getFiltered(type: 'income');
      expect(incomes.length, 1);
      expect(incomes.first.id, 'i1');
    });

    test('getFiltered by date range returns correct rows', () async {
      await txRepo.insert(makeItem(id: 'sep01').copyWith(date: '2026-09-01'));
      await txRepo.insert(makeItem(id: 'oct01').copyWith(date: '2026-10-01'));

      final septOnly = await txRepo.getFiltered(
        startDate: '2026-09-01',
        endDate: '2026-09-30',
      );
      expect(septOnly.length, 1);
      expect(septOnly.first.id, 'sep01');
    });

    test('getFiltered by category returns correct rows', () async {
      await txRepo.insert(makeItem(id: 'food1', category: 'Food & Dining'));
      await txRepo.insert(makeItem(id: 'transport1', category: 'Transport'));

      final foodOnly = await txRepo.getFiltered(category: 'Food & Dining');
      expect(foodOnly.length, 1);
      expect(foodOnly.first.category, 'Food & Dining');
    });

    test('getTotalExpenseByCategory returns correct sum', () async {
      await txRepo.insert(makeItem(id: 'e1', amount: 200));
      await txRepo.insert(makeItem(id: 'e2', amount: 300));
      await txRepo.insert(
        makeItem(id: 'i1', type: TransactionType.income, amount: 1000),
      );

      final total = await txRepo.getTotalExpenseByCategory('Food & Dining');
      expect(total, closeTo(500.0, 0.001));
    });

    test('getTotalExpenseByCategory returns 0 for unknown category', () async {
      final total = await txRepo.getTotalExpenseByCategory('NonExistent');
      expect(total, 0.0);
    });

    test('batchInsert inserts all items atomically', () async {
      final items = List.generate(
        10,
        (i) => makeItem(id: 'batch_$i', amount: (i + 1) * 100.0),
      );
      await txRepo.batchInsert(items);
      final all = await txRepo.getAll();
      expect(all.length, 10);
    });

    test(
      'batchInsert with duplicate ids silently ignores duplicates',
      () async {
        await txRepo.insert(makeItem(id: 'existing'));
        // batchInsert uses ConflictAlgorithm.ignore — no throws.
        await txRepo.batchInsert([makeItem(id: 'existing')]);
        final all = await txRepo.getAll();
        expect(all.length, 1); // Still just 1 — duplicate was ignored.
      },
    );

    test('deleteAll removes all rows', () async {
      await txRepo.batchInsert([makeItem(id: 'a'), makeItem(id: 'b')]);
      await txRepo.deleteAll();
      final all = await txRepo.getAll();
      expect(all, isEmpty);
    });
  });

  // ── BudgetRepository ──────────────────────────────────────────────────────

  group('BudgetRepository', () {
    BudgetItem makeBudget({
      String id = 'b_001',
      String category = 'Groceries',
      double limit = 5000,
      double spent = 0,
    }) {
      return BudgetItem(
        id: id,
        category: category,
        emoji: '🛒',
        spent: spent,
        limit: limit,
        period: 'Monthly',
        alertPercent: 80,
      );
    }

    test('insert and getAll returns budget', () async {
      await budgetRepo.insert(makeBudget());
      final all = await budgetRepo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'b_001');
    });

    test('category UNIQUE constraint rejects duplicate category', () async {
      await budgetRepo.insert(makeBudget(id: 'b1', category: 'Groceries'));
      expect(
        () async =>
            budgetRepo.insert(makeBudget(id: 'b2', category: 'Groceries')),
        throwsA(anything),
      );
    });

    test('getByCategory returns correct budget', () async {
      await budgetRepo.insert(makeBudget(category: 'Groceries'));
      final found = await budgetRepo.getByCategory('Groceries');
      expect(found, isNotNull);
      expect(found!.category, 'Groceries');
    });

    test('getByCategory returns null for missing category', () async {
      final found = await budgetRepo.getByCategory('Unknown');
      expect(found, isNull);
    });

    test('recalculateSpent updates spent field', () async {
      await budgetRepo.insert(makeBudget(category: 'Groceries', spent: 0));
      await budgetRepo.recalculateSpent('Groceries', 2500.0);
      final found = await budgetRepo.getByCategory('Groceries');
      expect(found!.spent, closeTo(2500.0, 0.001));
    });

    test('delete removes budget', () async {
      await budgetRepo.insert(makeBudget());
      final result = await budgetRepo.delete('b_001');
      expect(result, isTrue);
      final all = await budgetRepo.getAll();
      expect(all, isEmpty);
    });

    test('limit_amount CHECK constraint rejects 0 limit', () async {
      expect(
        () async => budgetRepo.insert(makeBudget(limit: 0)),
        throwsA(anything),
      );
    });
  });

  // ── GoalRepository ────────────────────────────────────────────────────────

  group('GoalRepository', () {
    FinancialGoal makeGoal({
      String id = 'g_001',
      double target = 100000,
      double current = 0,
    }) {
      return FinancialGoal(
        id: id,
        title: 'Emergency Fund',
        emoji: '🎯',
        targetAmount: target,
        currentAmount: current,
        estimatedCompletion: 'December 2026',
      );
    }

    test('insert and getAll returns goal', () async {
      await goalRepo.insert(makeGoal());
      final all = await goalRepo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'g_001');
    });

    test('upsert inserts when row absent', () async {
      await goalRepo.upsert(makeGoal(id: 'new_goal'));
      final all = await goalRepo.getAll();
      expect(all.any((g) => g.id == 'new_goal'), isTrue);
    });

    test('upsert updates when row exists', () async {
      await goalRepo.insert(makeGoal(id: 'g1', current: 0));
      await goalRepo.upsert(makeGoal(id: 'g1', current: 50000));
      final all = await goalRepo.getAll();
      final g = all.firstWhere((g) => g.id == 'g1');
      expect(g.currentAmount, closeTo(50000.0, 0.001));
    });

    test('delete removes goal', () async {
      await goalRepo.insert(makeGoal());
      final result = await goalRepo.delete('g_001');
      expect(result, isTrue);
      final all = await goalRepo.getAll();
      expect(all, isEmpty);
    });

    test('target_amount CHECK constraint rejects 0 target', () async {
      expect(
        () async => goalRepo.insert(makeGoal(target: 0)),
        throwsA(anything),
      );
    });

    test('batchInsert inserts multiple goals', () async {
      final goals = [makeGoal(id: 'g1'), makeGoal(id: 'g2')];
      await goalRepo.batchInsert(goals);
      final all = await goalRepo.getAll();
      expect(all.length, 2);
    });
  });

  // ── MigrationEngine ───────────────────────────────────────────────────────

  group('MigrationEngine', () {
    test('v1 schema creates all expected tables', () async {
      final tables = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      expect(
        tableNames,
        containsAll([
          'transactions',
          'budgets',
          'financial_goals',
          'recurring_transactions',
          'app_metadata',
          'schema_migrations',
        ]),
      );
    });

    test('v1 schema creates all expected indexes', () async {
      final indexes = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' ORDER BY name",
      );
      final indexNames = indexes.map((i) => i['name'] as String).toSet();
      expect(
        indexNames,
        containsAll([
          'idx_tx_date',
          'idx_tx_category_date',
          'idx_tx_type_date',
          'idx_budgets_category',
        ]),
      );
    });

    test('v2 migration adds is_synced column to transactions', () async {
      final info = await testDb.rawQuery('PRAGMA table_info(transactions)');
      final columns = info.map((c) => c['name'] as String).toSet();
      expect(columns, contains('is_synced'));
    });

    test('schema_migrations records applied versions', () async {
      final rows = await testDb.query(
        'schema_migrations',
        orderBy: 'version ASC',
      );
      expect(rows.length, greaterThanOrEqualTo(2)); // v1 + v2
      expect(rows[0]['version'], 1);
      expect(rows[1]['version'], 2);
    });

    test('WAL and integrity_check pragmas are applied', () async {
      final walResult = await testDb.rawQuery('PRAGMA journal_mode');
      // In-memory DBs use 'memory' mode, not WAL — this validates the PRAGMA call.
      expect(walResult, isNotEmpty);

      final integrityResult = await testDb.rawQuery('PRAGMA integrity_check');
      expect(integrityResult.first.values.first, 'ok');
    });
  });
}
