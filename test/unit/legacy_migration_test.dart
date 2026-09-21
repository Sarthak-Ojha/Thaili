// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:thaili/core/database/app_database.dart';
import 'package:thaili/core/database/budget_repository.dart';
import 'package:thaili/core/database/goal_repository.dart';
import 'package:thaili/core/database/legacy_data_migrator.dart';
import 'package:thaili/core/database/migration_engine.dart';
import 'package:thaili/core/database/recurring_repository.dart';
import 'package:thaili/core/database/transaction_repository.dart';

@GenerateMocks([AppDatabase])
import 'legacy_migration_test.mocks.dart';

Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return openDatabase(
    inMemoryDatabasePath,
    version: 2,
    onCreate: (db, v) => MigrationEngine.runMigrations(db, 0, v),
  );
}

void main() {
  late Database db;
  late MockAppDatabase mockDb;
  late TransactionRepository txRepo;
  late BudgetRepository budgetRepo;
  late GoalRepository goalRepo;
  late RecurringRepository recurringRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDb();
    mockDb = MockAppDatabase();
    when(mockDb.database).thenAnswer((_) async => db);

    txRepo = TransactionRepository(appDb: mockDb);
    budgetRepo = BudgetRepository(appDb: mockDb);
    goalRepo = GoalRepository(appDb: mockDb);
    recurringRepo = RecurringRepository(appDb: mockDb);
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await db.close();
  });

  group('LegacyDataMigrator', () {
    // ── No-op when migration already done ──────────────────────────────────
    test('skips migration when flag is already set', () async {
      SharedPreferences.setMockInitialValues({
        'db_migration_v1_done': true,
        'transactions': '[{"id":"tx1","title":"Tx","category":"Food","emoji":"💰","amount":500,"type":"expense","date":"2026-09-01","paymentMethod":"Cash","note":""}]',
      });

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      // Migration was skipped — nothing should be in DB.
      final txs = await txRepo.getAll();
      expect(txs, isEmpty);
    });

    // ── Transactions migration ─────────────────────────────────────────────
    test('migrates legacy transactions to SQLite', () async {
      const txJson = '[{"id":"tx_leg_001","title":"Salary","category":"Salary","emoji":"💼","amount":50000,"type":"income","date":"2026-09-01","paymentMethod":"Bank","note":"Monthly salary"}]';
      SharedPreferences.setMockInitialValues({'transactions': txJson});

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final txs = await txRepo.getAll();
      expect(txs.length, 1);
      expect(txs.first.id, 'tx_leg_001');
      expect(txs.first.amount, closeTo(50000.0, 0.001));
      expect(txs.first.title, 'Salary');
    });

    // ── Budgets migration ──────────────────────────────────────────────────
    test('migrates legacy budgets to SQLite', () async {
      const bgJson = '[{"id":"b_leg_001","category":"Groceries","emoji":"🛒","spent":1000,"limit":5000,"period":"Monthly","alertPercent":80}]';
      SharedPreferences.setMockInitialValues({'budgets': bgJson});

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final budgets = await budgetRepo.getAll();
      expect(budgets.length, 1);
      expect(budgets.first.id, 'b_leg_001');
      expect(budgets.first.limit, closeTo(5000.0, 0.001));
    });

    // ── Goals migration ────────────────────────────────────────────────────
    test('migrates legacy goals to SQLite', () async {
      const goalJson = '[{"id":"g_leg_001","title":"Emergency Fund","emoji":"🎯","targetAmount":100000,"currentAmount":25000,"estimatedCompletion":"December 2026"}]';
      SharedPreferences.setMockInitialValues({'goals': goalJson});

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final goals = await goalRepo.getAll();
      expect(goals.length, 1);
      expect(goals.first.targetAmount, closeTo(100000.0, 0.001));
      expect(goals.first.currentAmount, closeTo(25000.0, 0.001));
    });

    // ── Recurring migration ────────────────────────────────────────────────
    test('migrates legacy recurring transactions to SQLite', () async {
      const recJson = '[{"id":"rec_leg_001","title":"Monthly Rent","emoji":"🏠","amount":15000,"frequency":"Monthly","category":"Bills"}]';
      SharedPreferences.setMockInitialValues({'recurring': recJson});

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final recurring = await recurringRepo.getAll();
      expect(recurring.length, 1);
      expect(recurring.first.amount, closeTo(15000.0, 0.001));
    });

    // ── Mixed data migration ───────────────────────────────────────────────
    test('migrates all entity types in a single run', () async {
      SharedPreferences.setMockInitialValues({
        'transactions': '[{"id":"m_tx1","title":"T","category":"Food","emoji":"🍔","amount":200,"type":"expense","date":"2026-09-01","paymentMethod":"Cash","note":""}]',
        'budgets': '[{"id":"m_b1","category":"Transport","emoji":"🚗","spent":500,"limit":3000,"period":"Monthly","alertPercent":80}]',
        'goals': '[{"id":"m_g1","title":"Laptop","emoji":"💻","targetAmount":80000,"currentAmount":10000,"estimatedCompletion":"June 2027"}]',
        'recurring': '[{"id":"m_r1","title":"Internet","emoji":"🌐","amount":1500,"frequency":"Monthly","category":"Bills"}]',
      });

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      expect((await txRepo.getAll()).length, 1);
      expect((await budgetRepo.getAll()).length, 1);
      expect((await goalRepo.getAll()).length, 1);
      expect((await recurringRepo.getAll()).length, 1);
    });

    // ── Migration completion flag ──────────────────────────────────────────
    test('sets completion flag after migration', () async {
      SharedPreferences.setMockInitialValues({});
      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('db_migration_v1_done'), isTrue);
    });

    // ── Data preservation — archives v0 data ──────────────────────────────
    test('archives legacy data under v0 keys without deleting original', () async {
      const txJson = '[{"id":"arch_tx1","title":"Archived","category":"Food","emoji":"🍔","amount":300,"type":"expense","date":"2026-09-01","paymentMethod":"Cash","note":""}]';
      SharedPreferences.setMockInitialValues({'transactions': txJson});

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      final prefs = await SharedPreferences.getInstance();
      // v0 archive key must exist.
      expect(prefs.getString('transactions_v0'), isNotNull);
      // Original key must still be present (never deleted).
      expect(prefs.getString('transactions'), isNotNull);
    });

    // ── Malformed JSON resilience ──────────────────────────────────────────
    test('does not crash when legacy JSON is malformed', () async {
      SharedPreferences.setMockInitialValues({
        'transactions': 'NOT_VALID_JSON[[[',
      });

      // Must complete without throwing.
      await expectLater(
        LegacyDataMigrator.runIfNeeded(
          txRepo: txRepo,
          budgetRepo: budgetRepo,
          goalRepo: goalRepo,
          recurringRepo: recurringRepo,
        ),
        completes,
      );

      // DB should be empty (migration failed gracefully).
      final txs = await txRepo.getAll();
      expect(txs, isEmpty);
    });

    // ── Empty JSON arrays ──────────────────────────────────────────────────
    test('handles empty JSON arrays gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'transactions': '[]',
        'budgets': '[]',
        'goals': '[]',
        'recurring': '[]',
      });

      await LegacyDataMigrator.runIfNeeded(
        txRepo: txRepo,
        budgetRepo: budgetRepo,
        goalRepo: goalRepo,
        recurringRepo: recurringRepo,
      );

      expect(await txRepo.getAll(), isEmpty);
      expect(await budgetRepo.getAll(), isEmpty);
    });
  });
}
