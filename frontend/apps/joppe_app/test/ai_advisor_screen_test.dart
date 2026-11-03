import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/screens/ai_advisor_screen.dart';

void main() {
  testWidgets('AiAdvisorScreen renders greeting, quick chips, and input bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiAdvisorScreen(),
      ),
    );

    // Verify AppBar
    expect(find.text('Trợ Lý AI Joppe'), findsOneWidget);
    expect(find.text('Tư vấn phần cứng & Tương thích PC'), findsOneWidget);

    // Verify Welcome Assistant message
    expect(find.textContaining('Xin chào! Tôi là Trợ lý AI chuyên gia phần cứng của Joppe'), findsOneWidget);

    // Verify Initial Quick Chips
    expect(find.text('Build PC Gaming 15 triệu'), findsOneWidget);
    expect(find.text('Cấu hình đồ họa 3D / Render'), findsOneWidget);

    // Verify Input Bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });
}
