import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/main.dart';
import 'package:kaamsetu/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService().logout();
  });

  testWidgets('KaamSetu app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaamSetuApp());
    await tester.pumpAndSettle();

    expect(find.text('KaamSetu'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
  });
}
