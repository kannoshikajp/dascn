import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/main.dart';

void main() {
  testWidgets('JoppeApp smoke test renders header and catalog', (WidgetTester tester) async {
    await tester.pumpWidget(const JoppeApp());
    await tester.pump();

    // Verify that JOPPE logo, category button and cart badge are displayed
    expect(find.text('JOPPE'), findsWidgets);
    expect(find.text('DANH MỤC SẢN PHẨM'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart), findsWidgets);
  });
}
