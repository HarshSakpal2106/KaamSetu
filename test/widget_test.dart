import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/main.dart';

void main() {
  testWidgets('KaamSetu app loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KaamSetuApp());
    await tester.pumpAndSettle();

    // Verify that the brand name KaamSetu is found
    expect(find.text('KaamSetu'), findsWidgets);
  });
}
