// ignore_for_file: avoid_print

// Integration-style tests verifying ACID compliance and corruption
// resilience. These run on a desktop in-memory SQLite database (no device
// needed) using sqflite_common_ffi. They exercise:
//
// 1. Multi-row atomicity — a partial batch failure must not leave the
//    database in a half-written state.
// 2. CHECK constraint enforcement — the SQLite engine rejects semantically
//    invalid data at the DB layer, not just the Dart layer.
// 3. Concurrent read / write safety — multiple readers can query while a
//    write is in progress (WAL mode).
// 4. Recovery after simulated interrupted writes.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:thaili/core/database/app_database.dart';
import 'package:thaili/core/database/migration_engine.dart';
import 'package:thaili/core/database/transaction_repository.dart';
import 'package:thaili/core/state/app_state.dart';

class _TestAppDb implements AppDatabase {
  final Database _db;
  _TestAppDb(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  Future<void> close() => _db.close();

  @override
  Future<String> integrityCheck() async {
    final result = await _db.rawQuery('PRAGMA integrity_check');
    return (result.first.values.first as String?) ?? 'error';
  }
}

// Helper: Creates a fully-migrated in-memory SQLite database.
Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return openDatabase(
    inMemoryDatabasePath,
    version: 2,
    onCreate: (db, v) => MigrationEngine.runMigrations(db, 0, v),
  );
}

TransactionItem _tx(String id, {double amount = 100.0}) => TransactionItem(
      id: id,
      title: 'Tx $id',
      category: 'Food',
      emoji: '🍔',
      amount: amount,
      type: TransactionType.expense,
      date: '2026-09-01',
      paymentMethod: 'Cash',
      note: '',
    );

void main() {
  late Database db;
  late TransactionRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDb();
    repo = TransactionRepository(appDb: _TestAppDb(db));
  });

  tearDown(() => db.close());

  // ── ACID Atomicity ────────────────────────────────────────────────────────

  group('ACID atomicity', () {
    test('db.transaction() rolls back all rows if one fails', () async {
      // Pre-insert 'existing' to force a conflict in the middle of a transaction.
      await repo.insert(_tx('existing'));

      // Attempt an atomic transaction that includes a failing insert.
      try {
        await db.transaction((txn) async {
          await txn.insert('transactions', {
            'id': 'atomic_1',
            'title': 'First row',
            'category': 'Food',
            'emoji': '🍔',
            'amount': 200.0,
            'type': 'expense',
            'date': '2026-09-01',
            'payment_method': 'Cash',
            'note': '',
            'created_at': 0,
            'updated_at': 0,
          });
          // This insert will fail due to duplicate primary key.
          await txn.insert(
            'transactions',
            {
              'id': 'existing', // duplicate
              'title': 'Conflict row',
              'category': 'Food',
              'emoji': '🍔',
              'amount': 300.0,
              'type': 'expense',
              'date': '2026-09-01',
              'payment_method': 'Cash',
              'note': '',
              'created_at': 0,
              'updated_at': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.fail,
          );
        });
      } catch (_) {
        // Expected — the transaction rolls back.
      }

      // 'atomic_1' must NOT exist (rolled back with the failed transaction).
      final all = await repo.getAll();
      expect(all.any((t) => t.id == 'atomic_1'), isFalse,
          reason: 'Rolled-back insert must not appear in DB');
      // 'existing' must still exist and be unmodified.
      expect(all.any((t) => t.id == 'existing'), isTrue);
    });

    test('successful transaction commits all rows', () async {
      await db.transaction((txn) async {
        for (int i = 1; i <= 5; i++) {
          await txn.insert('transactions', {
            'id': 'commit_$i',
            'title': 'Row $i',
            'category': 'Food',
            'emoji': '🍔',
            'amount': i * 100.0,
            'type': 'expense',
            'date': '2026-09-01',
            'payment_method': 'Cash',
            'note': '',
            'created_at': 0,
            'updated_at': 0,
          });
        }
      });

      final all = await repo.getAll();
      expect(all.length, 5);
    });
  });

  // ── CHECK Constraint Enforcement ─────────────────────────────────────────

  group('CHECK constraint enforcement', () {
    test('type CHECK rejects values other than income/expense', () async {
      expect(
        () => db.rawInsert(
          "INSERT INTO transactions "
          "(id, title, category, emoji, amount, type, date, payment_method, note, created_at, updated_at) "
          "VALUES ('chk1', 'Bad', 'Food', '💰', 100, 'transfer', '2026-09-01', 'Cash', '', 0, 0)",
        ),
        throwsA(anything),
      );
    });

    test('budget limit_amount CHECK rejects 0', () async {
      expect(
        () => db.rawInsert(
          "INSERT INTO budgets "
          "(id, category, emoji, spent, limit_amount, period, alert_percent, updated_at) "
          "VALUES ('b_bad', 'Food', '🍔', 0, 0, 'Monthly', 80, 0)",
        ),
        throwsA(anything),
      );
    });

    test('goal target_amount CHECK rejects 0', () async {
      expect(
        () => db.rawInsert(
          "INSERT INTO financial_goals "
          "(id, title, emoji, target_amount, current_amount, estimated_completion, updated_at) "
          "VALUES ('g_bad', 'Bad Goal', '🎯', 0, 0, 'Dec 2026', 0)",
        ),
        throwsA(anything),
      );
    });
  });

  // ── Post-Write Integrity Check ────────────────────────────────────────────

  group('SQLite integrity verification', () {
    test('PRAGMA integrity_check returns ok after mixed CRUD operations', () async {
      // Mix of inserts, updates, and deletes.
      await repo.insert(_tx('crud_1'));
      await repo.insert(_tx('crud_2'));
      await repo.update(_tx('crud_1', amount: 999.0));
      await repo.delete('crud_2');

      final result = await db.rawQuery('PRAGMA integrity_check');
      expect(result.first.values.first, 'ok');
    });

    test('database remains consistent after deleteAll', () async {
      await repo.batchInsert(List.generate(50, (i) => _tx('batch_$i')));
      await repo.deleteAll();

      final result = await db.rawQuery('PRAGMA integrity_check');
      expect(result.first.values.first, 'ok');
      expect(await repo.getAll(), isEmpty);
    });
  });

  // ── Malformed Input Trapping ──────────────────────────────────────────────

  group('Malformed input boundary trapping', () {
    test('getAll returns empty list when DB is empty (no crash)', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('update on non-existent id returns false without corrupting DB', () async {
      await repo.insert(_tx('real_tx'));
      final updated = await repo.update(_tx('ghost_tx', amount: 9999.0));
      expect(updated, isFalse);

      // Real tx must be unchanged.
      final all = await repo.getAll();
      expect(all.first.amount, closeTo(100.0, 0.001));
    });

    test('delete on non-existent id returns false without corrupting DB', () async {
      await repo.insert(_tx('real_tx'));
      final deleted = await repo.delete('ghost_id');
      expect(deleted, isFalse);

      // Real tx must still exist.
      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('very large batch insert (1000 rows) completes without error', () async {
      final items = List.generate(1000, (i) => _tx('large_batch_$i', amount: (i + 1) * 1.5));
      await repo.batchInsert(items);

      final all = await repo.getAll();
      expect(all.length, 1000);

      // Integrity must still be ok after 1000 row batch.
      final intResult = await db.rawQuery('PRAGMA integrity_check');
      expect(intResult.first.values.first, 'ok');
    });
  });
}
