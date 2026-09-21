import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/state/app_state.dart';
import 'package:thaili/core/theme/app_theme.dart';
import 'package:thaili/features/budgets/create_budget_dialog.dart';


Future<void> pumpBudgetDialog(WidgetTester tester,
    {String currSymbol = 'Rs.'}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: CreateBudgetDialog(currSymbol: currSymbol),
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
  group('CreateBudgetDialog – rendering', () {
    testWidgets('renders New Budget title', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('New Budget'), findsOneWidget);
    });

    testWidgets('renders Create Budget button', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('Create Budget'), findsOneWidget);
    });

    testWidgets('renders Budget Title and Budget Limit labels', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('Budget Title'), findsOneWidget);
      expect(find.text('Budget Limit'), findsOneWidget);
    });

    testWidgets('renders Period and Alert when labels', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('Period'), findsOneWidget);
      expect(find.text('Alert when'), findsOneWidget);
    });

    testWidgets('shows default period as Monthly', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('shows default alert percent as 80%', (tester) async {
      await pumpBudgetDialog(tester);
      expect(find.text('80%'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Validation
  // --------------------------------------------------------------------------
  group('CreateBudgetDialog – validation', () {
    testWidgets('empty title shows SnackBar error', (tester) async {
      await pumpBudgetDialog(tester);
      // Do not enter any title
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(find.text('Please enter a budget title'), findsOneWidget);
    });

    testWidgets('empty limit shows SnackBar error', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Groceries');
      // Do not enter a limit
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(find.text('Please enter a valid budget limit amount'), findsOneWidget);
    });

    testWidgets('zero limit shows SnackBar error', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Groceries');
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(find.text('Please enter a valid budget limit amount'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Successful creation
  // --------------------------------------------------------------------------
  group('CreateBudgetDialog – successful creation', () {
    testWidgets('valid inputs add budget to AppStateModel', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Transport');
      await tester.enterText(find.byType(TextField).last, '5000');
      await tester.tap(find.text('Create Budget'));
      await tester.pump();

      // Budget should be added to the singleton state
      expect(AppStateModel().budgets.length, 1);
      expect(AppStateModel().budgets.first.category, 'Transport');
      expect(AppStateModel().budgets.first.limit, 5000.0);
    });

    testWidgets('created budget has spent of 0.0', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Food');
      await tester.enterText(find.byType(TextField).last, '3000');
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(AppStateModel().budgets.first.spent, 0.0);
    });

    testWidgets('created budget has correct alertPercent of 80', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Health');
      await tester.enterText(find.byType(TextField).last, '2000');
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(AppStateModel().budgets.first.alertPercent, 80);
    });

    testWidgets('handles comma-separated limit input', (tester) async {
      await pumpBudgetDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Shopping');
      await tester.enterText(find.byType(TextField).last, '10,000');
      await tester.tap(find.text('Create Budget'));
      await tester.pump();
      expect(AppStateModel().budgets.first.limit, 10000.0);
    });
  });
}
