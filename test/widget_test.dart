import 'package:flutter_test/flutter_test.dart';
import 'package:thaili/main.dart';

void main() {
  testWidgets('App renders splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ThailiApp());
    expect(find.text('THAILI'), findsOneWidget);
    expect(find.text('Your money, your way.'), findsOneWidget);
  });
}
