import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/main.dart';

void main() {
  testWidgets('JoppeApp smoke test renders navigation and catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const JoppeApp());
    expect(find.text('Joppe Store'), findsOneWidget);
    expect(find.text('Catalog'), findsWidgets);
  });
}
