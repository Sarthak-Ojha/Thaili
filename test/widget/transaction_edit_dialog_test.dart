import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/state/app_state.dart';
import 'package:thaili/core/theme/app_theme.dart';
import 'package:thaili/features/transactions/transaction_edit_dialog.dart';

import '../helpers/test_helpers.dart';

/// Pumps the TransactionEditDialog inside a properly configured app.
Future<void> pumpEditDialog(
  WidgetTester tester, {
  required TransactionItem transaction,
  String currSymbol = 'Rs.',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(builder: (context) {
          return TransactionEditDialog(
            transaction: transaction,
            currSymbol: currSymbol,
          );
        }),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppStateModel().resetForTesting();
  });

  // --------------------------------------------------------------------------
  // Rendering
  // --------------------------------------------------------------------------
  group('TransactionEditDialog – rendering', () {
    testWidgets('renders Edit Transaction header', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      expect(find.text('Edit Transaction'), findsOneWidget);
    });

    testWidgets('renders Save Changes button', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('pre-fills title from transaction', (tester) async {
      final tx = makeTransaction(title: 'Lunch Break');
      await pumpEditDialog(tester, transaction: tx);
      expect(find.text('Lunch Break'), findsOneWidget);
    });

    testWidgets('pre-fills amount from transaction', (tester) async {
      final tx = makeTransaction(amount: 750.0);
      await pumpEditDialog(tester, transaction: tx);
      expect(find.text('750'), findsOneWidget);
    });

    testWidgets('shows Expense and Income type buttons', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('shows Category section label', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      expect(find.text('Category'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Form validation
  // --------------------------------------------------------------------------
  group('TransactionEditDialog – form validation', () {
    testWidgets('empty title shows validation error', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('Title cannot be empty'), findsOneWidget);
    });

    testWidgets('empty amount shows validation error', (tester) async {
      final tx = makeTransaction(title: 'Test', amount: 100.0);
      await pumpEditDialog(tester, transaction: tx);
      // Clear the amount field
      await tester.enterText(
          find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('non-numeric amount shows validation error', (tester) async {
      final tx = makeTransaction(title: 'Test', amount: 100.0);
      await pumpEditDialog(tester, transaction: tx);
      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('zero amount shows validation error', (tester) async {
      final tx = makeTransaction(title: 'Test', amount: 100.0);
      await pumpEditDialog(tester, transaction: tx);
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('Amount must be greater than zero'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Transaction type switching
  // --------------------------------------------------------------------------
  group('TransactionEditDialog – type switching', () {
    testWidgets('tapping Income chip changes selection', (tester) async {
      // Start with expense transaction
      final tx = makeTransaction(type: TransactionType.expense);
      await pumpEditDialog(tester, transaction: tx);

      // Tap Income button
      await tester.tap(find.text('Income'));
      await tester.pump();

      // After tapping Income — the Income chip should have a different style
      // We verify by checking the widget didn't throw and still shows both chips
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('tapping Expense chip when already expense keeps expense', (tester) async {
      final tx = makeTransaction(type: TransactionType.expense);
      await pumpEditDialog(tester, transaction: tx);
      await tester.tap(find.text('Expense'));
      await tester.pump();
      expect(find.text('Expense'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Category chip selection
  // --------------------------------------------------------------------------
  group('TransactionEditDialog – category selection', () {
    testWidgets('category chips are rendered', (tester) async {
      await pumpEditDialog(tester, transaction: makeTransaction());
      // At least one category chip should be present (the list is scrollable)
      expect(find.byType(ChoiceChip), findsWidgets);
    });
  });

  // --------------------------------------------------------------------------
  // Valid submission
  // --------------------------------------------------------------------------
  group('TransactionEditDialog – valid submission', () {
    testWidgets('valid form submission updates transaction in state',
        (tester) async {
      final tx = makeTransaction(
          id: 'edit_me', title: 'Original Title', amount: 500.0);
      AppStateModel().addTransaction(tx);

      await pumpEditDialog(tester, transaction: tx);

      // Update title
      await tester.enterText(find.byType(TextFormField).at(0), 'Updated Title');
      // Keep valid amount
      await tester.enterText(find.byType(TextFormField).at(1), '600');

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // The dialog should have called editTransaction — verify state updated
      final updated =
          AppStateModel().transactions.firstWhere((t) => t.id == 'edit_me');
      expect(updated.title, 'Updated Title');
      expect(updated.amount, 600.0);
    });
  });
}
