import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/database/app_database.dart';
import 'package:thaili/core/services/backup_manager.dart';
import 'package:thaili/core/state/app_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  // Reset singleton + prefs before every test
  setUp(() async {
    await resetState();
    AppStateModel.enablePersistence = true;
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('financial_goals');
      await db.delete('recurring_transactions');
      await db.delete('app_metadata');
    } catch (_) {}
  });

  tearDown(() {
    AppStateModel.enablePersistence = false;
  });

  // --------------------------------------------------------------------------
  // AppStateModel – initial defaults
  // --------------------------------------------------------------------------
  group('AppStateModel – default values', () {
    test('starts with empty lists and zero balances', () {
      final state = AppStateModel();
      expect(state.transactions, isEmpty);
      expect(state.budgets, isEmpty);
      expect(state.goals, isEmpty);
      expect(state.recurring, isEmpty);
      expect(state.initialBalance, 0.0);
      expect(state.totalIncome, 0.0);
      expect(state.totalExpenses, 0.0);
      expect(state.netSavings, 0.0);
    });

    test('default language is english', () {
      expect(AppStateModel().language, AppLanguage.english);
    });

    test('default currency is npr', () {
      expect(AppStateModel().currency, AppCurrency.npr);
    });

    test('default themeMode is system', () {
      expect(AppStateModel().themeMode, ThemeMode.system);
    });

    test('default isOnboarded is false', () {
      expect(AppStateModel().isOnboarded, false);
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Transaction CRUD
  // --------------------------------------------------------------------------
  group('AppStateModel – Transaction CRUD', () {
    test('addTransaction inserts at index 0', () {
      final state = AppStateModel();
      final tx1 = makeTransaction(id: 'tx_1', title: 'First');
      final tx2 = makeTransaction(id: 'tx_2', title: 'Second');
      state.addTransaction(tx1);
      state.addTransaction(tx2);
      expect(state.transactions.first.id, 'tx_2');
      expect(state.transactions.length, 2);
    });

    test('addTransaction expense decreases initialBalance', () {
      final state = AppStateModel();
      state.setInitialBalance(1000.0);
      state.addTransaction(
          makeTransaction(amount: 300.0, type: TransactionType.expense));
      expect(state.initialBalance, closeTo(700.0, 0.001));
    });

    test('addTransaction income increases initialBalance', () {
      final state = AppStateModel();
      state.setInitialBalance(500.0);
      state.addTransaction(
          makeTransaction(amount: 200.0, type: TransactionType.income));
      expect(state.initialBalance, closeTo(700.0, 0.001));
    });

    test('editTransaction reverts old effect and applies new effect', () {
      final state = AppStateModel();
      state.setInitialBalance(1000.0);
      final original =
          makeTransaction(id: 'tx_e', amount: 300.0, type: TransactionType.expense);
      state.addTransaction(original); // balance = 700
      expect(state.initialBalance, closeTo(700.0, 0.001));

      // Edit: change to income of 200
      final edited = original.copyWith(
          amount: 200.0, type: TransactionType.income);
      state.editTransaction(edited);
      // Revert expense 300 (+300) = 1000, then apply income 200 (+200) = 1200
      expect(state.initialBalance, closeTo(1200.0, 0.001));
    });

    test('editTransaction on non-existent id does nothing', () {
      final state = AppStateModel();
      state.setInitialBalance(1000.0);
      state.editTransaction(makeTransaction(id: 'no_such_id'));
      expect(state.initialBalance, 1000.0);
      expect(state.transactions, isEmpty);
    });

    test('deleteTransaction restores balance for expense', () {
      final state = AppStateModel();
      state.setInitialBalance(1000.0);
      final tx = makeTransaction(id: 'del_tx', amount: 400.0);
      state.addTransaction(tx); // balance = 600
      state.deleteTransaction('del_tx'); // balance back to 1000
      expect(state.initialBalance, closeTo(1000.0, 0.001));
      expect(state.transactions, isEmpty);
    });

    test('deleteTransaction restores balance for income', () {
      final state = AppStateModel();
      state.setInitialBalance(500.0);
      final tx = makeTransaction(
          id: 'del_inc', amount: 300.0, type: TransactionType.income);
      state.addTransaction(tx); // balance = 800
      state.deleteTransaction('del_inc'); // balance back to 500
      expect(state.initialBalance, closeTo(500.0, 0.001));
    });

    test('deleteTransaction on non-existent id does nothing', () {
      final state = AppStateModel();
      state.setInitialBalance(1000.0);
      state.deleteTransaction('ghost_id');
      expect(state.initialBalance, 1000.0);
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Computed financial properties
  // --------------------------------------------------------------------------
  group('AppStateModel – financial calculations', () {
    test('totalIncome sums only income transactions', () {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(
          id: 't1', amount: 500.0, type: TransactionType.income));
      state.addTransaction(makeTransaction(
          id: 't2', amount: 300.0, type: TransactionType.income));
      state.addTransaction(
          makeTransaction(id: 't3', amount: 100.0, type: TransactionType.expense));
      expect(state.totalIncome, closeTo(800.0, 0.001));
    });

    test('totalExpenses sums only expense transactions', () {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(
          id: 't1', amount: 200.0, type: TransactionType.expense));
      state.addTransaction(makeTransaction(
          id: 't2', amount: 150.0, type: TransactionType.expense));
      state.addTransaction(makeTransaction(
          id: 't3', amount: 1000.0, type: TransactionType.income));
      expect(state.totalExpenses, closeTo(350.0, 0.001));
    });

    test('netSavings is totalIncome minus totalExpenses', () {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(
          id: 'i1', amount: 5000.0, type: TransactionType.income));
      state.addTransaction(makeTransaction(
          id: 'e1', amount: 2000.0, type: TransactionType.expense));
      expect(state.netSavings, closeTo(3000.0, 0.001));
    });

    test('netSavings is negative when expenses exceed income', () {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(
          id: 'i1', amount: 1000.0, type: TransactionType.income));
      state.addTransaction(makeTransaction(
          id: 'e1', amount: 3000.0, type: TransactionType.expense));
      expect(state.netSavings, closeTo(-2000.0, 0.001));
    });

    test('totalBudgetSpent aggregates all budget spent values', () {
      final state = AppStateModel();
      state.addBudget(makeBudget(id: 'b1', spent: 200.0));
      state.addBudget(makeBudget(id: 'b2', spent: 350.0));
      expect(state.totalBudgetSpent, closeTo(550.0, 0.001));
    });

    test('totalBudgetLimit aggregates all budget limits', () {
      final state = AppStateModel();
      state.addBudget(makeBudget(id: 'b1', limit: 500.0));
      state.addBudget(makeBudget(id: 'b2', limit: 1000.0));
      expect(state.totalBudgetLimit, closeTo(1500.0, 0.001));
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Budget CRUD
  // --------------------------------------------------------------------------
  group('AppStateModel – Budget CRUD', () {
    test('addBudget appends to list', () {
      final state = AppStateModel();
      state.addBudget(makeBudget(id: 'b1'));
      state.addBudget(makeBudget(id: 'b2'));
      expect(state.budgets.length, 2);
    });

    test('deleteBudget removes correct item by id', () {
      final state = AppStateModel();
      state.addBudget(makeBudget(id: 'keep'));
      state.addBudget(makeBudget(id: 'remove'));
      state.deleteBudget('remove');
      expect(state.budgets.length, 1);
      expect(state.budgets.first.id, 'keep');
    });

    test('deleteBudget with non-existent id does not throw', () {
      final state = AppStateModel();
      state.addBudget(makeBudget(id: 'b1'));
      state.deleteBudget('ghost');
      expect(state.budgets.length, 1);
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Goals CRUD
  // --------------------------------------------------------------------------
  group('AppStateModel – Goals CRUD', () {
    test('addGoal inserts at index 0', () {
      final state = AppStateModel();
      state.addGoal(makeGoal(id: 'g1', title: 'First'));
      state.addGoal(makeGoal(id: 'g2', title: 'Second'));
      expect(state.goals.first.id, 'g2');
    });

    test('setGoal replaces first goal when one already exists', () {
      final state = AppStateModel();
      state.addGoal(makeGoal(id: 'g_old', title: 'Old Goal'));
      final newGoal = makeGoal(id: 'g_new', title: 'New Goal');
      state.setGoal(newGoal);
      expect(state.goals.length, 1);
      expect(state.goals.first.id, 'g_new');
    });

    test('setGoal adds goal when list is empty', () {
      final state = AppStateModel();
      state.setGoal(makeGoal(id: 'g1', title: 'My Goal'));
      expect(state.goals.length, 1);
    });

    test('goal getter returns first goal', () {
      final state = AppStateModel();
      state.addGoal(makeGoal(id: 'g1'));
      expect(state.goal, isNotNull);
      expect(state.goal!.id, 'g1');
    });

    test('goal getter returns null when goals is empty', () {
      expect(AppStateModel().goal, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Recurring CRUD
  // --------------------------------------------------------------------------
  group('AppStateModel – Recurring CRUD', () {
    test('addRecurring appends to list', () {
      final state = AppStateModel();
      state.addRecurring(makeRecurring(id: 'r1'));
      state.addRecurring(makeRecurring(id: 'r2'));
      expect(state.recurring.length, 2);
    });

    test('deleteRecurring removes by id', () {
      final state = AppStateModel();
      state.addRecurring(makeRecurring(id: 'r_keep'));
      state.addRecurring(makeRecurring(id: 'r_del'));
      state.deleteRecurring('r_del');
      expect(state.recurring.length, 1);
      expect(state.recurring.first.id, 'r_keep');
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – Currency & Language switching
  // --------------------------------------------------------------------------
  group('AppStateModel – currency and language', () {
    test('setCurrency updates currency and currentCurrencyData', () {
      final state = AppStateModel();
      state.setCurrency(AppCurrency.usd);
      expect(state.currency, AppCurrency.usd);
      expect(state.currentCurrencyData.code, 'USD');
      expect(state.currentCurrencyData.symbol, '\$');
    });

    test('setCurrency to same value does not fire unnecessary work', () {
      final state = AppStateModel();
      // Already NPR by default — calling setCurrency(npr) again is a no-op
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.setCurrency(AppCurrency.npr);
      expect(notifyCount, 0);
      state.removeListener(() {});
    });

    test('setCurrency to INR returns INR data', () {
      final state = AppStateModel();
      state.setCurrency(AppCurrency.inr);
      expect(state.currentCurrencyData.code, 'INR');
      expect(state.currentCurrencyData.symbol, '₹');
    });

    test('setLanguage updates language', () {
      final state = AppStateModel();
      state.setLanguage(AppLanguage.nepali);
      expect(state.language, AppLanguage.nepali);
    });

    test('setLanguage to same value is a no-op (no notify)', () {
      final state = AppStateModel();
      int count = 0;
      state.addListener(() => count++);
      state.setLanguage(AppLanguage.english);
      expect(count, 0);
      state.removeListener(() {});
    });

    test('currentCurrencyData getName returns correct locale string', () {
      final state = AppStateModel();
      state.setCurrency(AppCurrency.npr);
      final data = state.currentCurrencyData;
      expect(data.getName(AppLanguage.english), contains('NPR'));
      expect(data.getName(AppLanguage.nepali), contains('NPR'));
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – setUserName capitalization
  // --------------------------------------------------------------------------
  group('AppStateModel – setUserName', () {
    test('capitalizes each word', () {
      AppStateModel().setUserName('john doe');
      expect(AppStateModel().userName, 'John Doe');
    });

    test('handles single word', () {
      AppStateModel().setUserName('SARTHAK');
      expect(AppStateModel().userName, 'Sarthak');
    });

    test('handles mixed case multi-word', () {
      AppStateModel().setUserName('  rAm  bAhadur  ');
      expect(AppStateModel().userName, 'Ram Bahadur');
    });

    test('non-empty name marks user as onboarded', () {
      AppStateModel().setUserName('Alice');
      expect(AppStateModel().isOnboarded, true);
    });

    test('empty name does not mark as onboarded', () {
      AppStateModel().setUserName('');
      expect(AppStateModel().isOnboarded, false);
      expect(AppStateModel().userName, '');
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – init() loads from SharedPreferences
  // --------------------------------------------------------------------------
  group('AppStateModel – init() persistence round-trip', () {
    test('init() reads language from prefs', () async {
      SharedPreferences.setMockInitialValues({'language': 'nepali'});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().language, AppLanguage.nepali);
    });

    test('init() reads currency from prefs', () async {
      SharedPreferences.setMockInitialValues({'currency': 'usd'});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().currency, AppCurrency.usd);
    });

    test('init() reads INR from prefs', () async {
      SharedPreferences.setMockInitialValues({'currency': 'inr'});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().currency, AppCurrency.inr);
    });

    test('init() reads initialBalance from prefs', () async {
      SharedPreferences.setMockInitialValues({'initialBalance': 12345.0});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().initialBalance, closeTo(12345.0, 0.001));
    });

    test('init() sets isOnboarded true when userName is present', () async {
      SharedPreferences.setMockInitialValues({'userName': 'Alice'});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().isOnboarded, true);
    });

    test('init() reads transactions from prefs JSON', () async {
      final tx = makeTransaction(id: 'tx_prefs');
      final json = jsonEncode([tx.toJson()]);
      SharedPreferences.setMockInitialValues({'transactions': json});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().transactions.length, 1);
      expect(AppStateModel().transactions.first.id, 'tx_prefs');
    });

    test('init() reads budgets from prefs JSON', () async {
      final b = makeBudget(id: 'b_prefs');
      final json = jsonEncode([b.toJson()]);
      SharedPreferences.setMockInitialValues({'budgets': json});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().budgets.length, 1);
      expect(AppStateModel().budgets.first.id, 'b_prefs');
    });

    test('init() reads goals from prefs JSON', () async {
      final g = makeGoal(id: 'g_prefs');
      final json = jsonEncode([g.toJson()]);
      SharedPreferences.setMockInitialValues({'goals': json});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().goals.length, 1);
      expect(AppStateModel().goals.first.id, 'g_prefs');
    });

    test('init() reads recurring from prefs JSON', () async {
      final r = makeRecurring(id: 'r_prefs');
      final json = jsonEncode([r.toJson()]);
      SharedPreferences.setMockInitialValues({'recurring': json});
      AppStateModel().resetForTesting();
      await AppStateModel().init();
      expect(AppStateModel().recurring.length, 1);
      expect(AppStateModel().recurring.first.id, 'r_prefs');
    });
  });

  // --------------------------------------------------------------------------
  // AppStateModel – saveToPrefs() writes correct keys
  // --------------------------------------------------------------------------
  group('AppStateModel – saveToPrefs()', () {
    test('persists language and currency', () async {
      final state = AppStateModel();
      state.setLanguage(AppLanguage.nepali);
      state.setCurrency(AppCurrency.usd);
      await state.saveToPrefs();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'nepali');
      expect(prefs.getString('currency'), 'usd');
    });

    test('persists themeMode index', () async {
      final state = AppStateModel();
      state.setThemeMode(ThemeMode.dark);
      await state.saveToPrefs();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('themeMode'), ThemeMode.dark.index);
    });

    test('persists transactions as JSON', () async {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(id: 'save_tx'));
      await state.saveToPrefs();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('transactions');
      expect(raw, isNotNull);
      final list = jsonDecode(raw!) as List;
      expect(list.length, 1);
      expect(list.first['id'], 'save_tx');
    });
  });

  // --------------------------------------------------------------------------
  // BackupManager
  // --------------------------------------------------------------------------
  group('BackupManager', () {
    test('performBackup returns valid JSON string', () async {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(id: 'bk_tx'));
      state.addBudget(makeBudget(id: 'bk_b'));
      state.addGoal(makeGoal(id: 'bk_g'));
      state.addRecurring(makeRecurring(id: 'bk_r'));

      final result = await BackupManager.performBackup(state);
      expect(result, isNotNull);
      expect(() => jsonDecode(result!), returnsNormally);
    });

    test('backup JSON contains all required keys', () async {
      final result = await BackupManager.performBackup(AppStateModel());
      final data = jsonDecode(result!) as Map<String, dynamic>;
      expect(data.containsKey('version'), true);
      expect(data.containsKey('timestamp'), true);
      expect(data.containsKey('balance'), true);
      expect(data.containsKey('transactions'), true);
      expect(data.containsKey('budgets'), true);
      expect(data.containsKey('goals'), true);
      expect(data.containsKey('recurring'), true);
    });

    test('backup version is 1', () async {
      final result = await BackupManager.performBackup(AppStateModel());
      final data = jsonDecode(result!) as Map<String, dynamic>;
      expect(data['version'], 1);
    });

    test('backup timestamp parses as valid DateTime', () async {
      final result = await BackupManager.performBackup(AppStateModel());
      final data = jsonDecode(result!) as Map<String, dynamic>;
      expect(() => DateTime.parse(data['timestamp'] as String), returnsNormally);
    });

    test('backup includes transaction data', () async {
      final state = AppStateModel();
      state.addTransaction(makeTransaction(id: 'bk_tx2', title: 'Lunch'));
      final result = await BackupManager.performBackup(state);
      final data = jsonDecode(result!) as Map<String, dynamic>;
      final txList = data['transactions'] as List;
      expect(txList.length, 1);
      expect(txList.first['id'], 'bk_tx2');
    });
  });
}
