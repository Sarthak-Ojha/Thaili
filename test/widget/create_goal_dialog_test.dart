import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaili/core/state/app_state.dart';
import 'package:thaili/core/theme/app_theme.dart';
import 'package:thaili/features/goals/create_goal_dialog.dart';


Future<void> pumpGoalDialog(WidgetTester tester,
    {String currSymbol = 'Rs.'}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: CreateGoalDialog(currSymbol: currSymbol),
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
  group('CreateGoalDialog – rendering', () {
    testWidgets('renders New Goal title', (tester) async {
      await pumpGoalDialog(tester);
      expect(find.text('New Goal'), findsOneWidget);
    });

    testWidgets('renders Create Goal button', (tester) async {
      await pumpGoalDialog(tester);
      expect(find.text('Create Goal'), findsOneWidget);
    });

    testWidgets('renders Goal Name and Target Amount labels', (tester) async {
      await pumpGoalDialog(tester);
      expect(find.text('Goal Name'), findsOneWidget);
      expect(find.text('Target Amount'), findsOneWidget);
    });

    testWidgets('renders currency symbol', (tester) async {
      await pumpGoalDialog(tester, currSymbol: '₹');
      expect(find.text('₹ '), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // Default fallback behavior
  // --------------------------------------------------------------------------
  group('CreateGoalDialog – default fallbacks', () {
    testWidgets('empty title creates goal with "Financial Goal" default', (tester) async {
      await pumpGoalDialog(tester);
      // Leave title empty
      await tester.enterText(find.byType(TextField).last, '50000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.isNotEmpty, true);
      expect(AppStateModel().goals.first.title, 'Financial Goal');
    });

    testWidgets('empty target amount uses 50000.0 fallback', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'New Laptop');
      // Leave target empty
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.first.targetAmount, 50000.0);
    });

    testWidgets('zero target amount uses 50000.0 fallback', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Trip');
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.first.targetAmount, 50000.0);
    });
  });

  // --------------------------------------------------------------------------
  // Successful creation
  // --------------------------------------------------------------------------
  group('CreateGoalDialog – successful creation', () {
    testWidgets('valid inputs create goal in AppStateModel', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Emergency Fund');
      await tester.enterText(find.byType(TextField).last, '100000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.length, 1);
      expect(AppStateModel().goals.first.title, 'Emergency Fund');
      expect(AppStateModel().goals.first.targetAmount, 100000.0);
    });

    testWidgets('new goal starts with currentAmount of 0.0', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Savings');
      await tester.enterText(find.byType(TextField).last, '25000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.first.currentAmount, 0.0);
    });

    testWidgets('new goal emoji is 🎯', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Car');
      await tester.enterText(find.byType(TextField).last, '500000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.first.emoji, '🎯');
    });

    testWidgets('estimatedCompletion year is currentYear + 1', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'Vacation');
      await tester.enterText(find.byType(TextField).last, '80000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      final expectedYear = (DateTime.now().year + 1).toString();
      expect(AppStateModel().goals.first.estimatedCompletion,
          contains(expectedYear));
    });

    testWidgets('handles comma-separated target input', (tester) async {
      await pumpGoalDialog(tester);
      await tester.enterText(find.byType(TextField).first, 'House Down Payment');
      await tester.enterText(find.byType(TextField).last, '5,00,000');
      await tester.tap(find.text('Create Goal'));
      await tester.pump();

      expect(AppStateModel().goals.first.targetAmount, 500000.0);
    });
  });
}
