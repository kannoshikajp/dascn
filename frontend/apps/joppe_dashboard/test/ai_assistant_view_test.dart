import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/ai_assistant_view.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late AdminAiService aiService;

  Widget buildTestWidget() {
    return MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: AiAssistantView(
          aiService: aiService,
        ),
      ),
    );
  }

  testWidgets('renders AiAssistantView with welcome prompt and quick action chips', (tester) async {
    mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
    apiClient = ApiClient(client: mockClient);
    aiService = AdminAiService(apiClient);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý AI Vận hành Joppe'), findsOneWidget);
    expect(find.text('Kiểm tra linh kiện sắp hết hàng'), findsOneWidget);
    expect(find.text('Thống kê doanh thu & đơn hàng'), findsOneWidget);
    expect(find.text('Tìm card đồ họa RTX 4070'), findsOneWidget);
  });

  testWidgets('clicking prompt chip sends question and renders AI response with tool badges and product cards', (tester) async {
    mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/v1/admin/ai/chat')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['message'], 'Kiểm tra linh kiện sắp hết hàng');

        final responseJson = {
          'answer': 'Tìm thấy 1 linh kiện đang có tồn kho dưới ngưỡng an toàn.',
          'referencedProducts': [
            {
              'id': 'v-101',
              'sku': 'GPU-RTX4070-OC',
              'name': 'ASUS Dual GeForce RTX 4070 OC',
              'minPrice': 16500000,
              'maxPrice': 16500000,
              'totalStock': 3,
            }
          ],
          'executedTools': ['check_inventory_stock'],
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('Not Found', 404);
    });
    apiClient = ApiClient(client: mockClient);
    aiService = AdminAiService(apiClient);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap quick action chip
    final chip = find.text('Kiểm tra linh kiện sắp hết hàng');
    await tester.tap(chip);
    await tester.pump(); // Start request
    await tester.pumpAndSettle(); // Settle response

    // Verify AI answer rendered
    expect(find.text('Tìm thấy 1 linh kiện đang có tồn kho dưới ngưỡng an toàn.'), findsOneWidget);
    // Verify tool badge
    expect(find.text('check_inventory_stock'), findsOneWidget);
    // Verify referenced product card
    expect(find.text('ASUS Dual GeForce RTX 4070 OC'), findsOneWidget);
    expect(find.text('GPU-RTX4070-OC'), findsOneWidget);
    expect(find.text('Tồn: 3'), findsOneWidget);
  });
}
