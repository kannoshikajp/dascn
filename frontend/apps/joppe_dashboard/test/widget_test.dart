import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_dashboard/main.dart';

void main() {
  testWidgets('JoppeDashboardApp smoke test renders navigation and overview', (WidgetTester tester) async {
    await tester.pumpWidget(const JoppeDashboardApp());
    expect(find.text('Joppe Control Center'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
  });
}
