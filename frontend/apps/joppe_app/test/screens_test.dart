import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/data/hardware_mock_data.dart';
import 'package:joppe_app/src/screens/build_pc_screen.dart';
import 'package:joppe_app/src/screens/home_screen.dart';
import 'package:joppe_app/src/screens/product_details_screen.dart';

void main() {
  testWidgets('ProductDetailsScreen displays product info and prices', (WidgetTester tester) async {
    final product = HardwareMockData.products.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsScreen(product: product),
      ),
    );

    // Verify brand on title
    expect(find.text(product.brand.toUpperCase()), findsOneWidget);

    // Verify product name
    expect(find.text(product.name), findsOneWidget);

    // Verify pure VND price
    expect(find.text(product.formattedPrice), findsOneWidget);
    if (product.originalPrice != null && product.discountPercentage > 0) {
      expect(find.text(product.formattedOriginalPrice), findsOneWidget);
    }

    // Verify technical specs section
    if (product.technicalSpecs.isNotEmpty) {
      expect(find.text('THÔNG SỐ KỸ THUẬT CHI TIẾT'), findsOneWidget);
    }

    // Verify action buttons
    expect(find.text('THÊM GIỎ HÀNG'), findsOneWidget);
    expect(find.text('MUA NGAY'), findsOneWidget);
  });

  testWidgets('BuildPcScreen renders correctly with slots and total bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuildPcScreen(),
      ),
    );

    // Verify screen title
    expect(find.text('XÂY DỰNG CẤU HÌNH PC'), findsOneWidget);

    // Verify slot names
    expect(find.text('CPU - Bộ Vi Xử Lý'), findsOneWidget);
    expect(find.text('Mainboard - Bo Mạch Chủ'), findsOneWidget);

    // Verify bottom total bar
    expect(find.text('TỔNG CHI PHÍ DỰ KIẾN'), findsOneWidget);
    expect(find.text('0 ₫'), findsOneWidget);
    expect(find.text('THÊM VÀO GIỎ HÀNG'), findsOneWidget);
  });

  testWidgets('BuildPcScreen renders without RenderFlex overflow on small 360x640 mobile screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: BuildPcScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('XÂY DỰNG CẤU HÌNH PC'), findsOneWidget);
    expect(find.text('JOPPE'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.calculate_outlined), findsWidgets);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('HomeScreen renders header, category bar, quick actions, and product catalog', (WidgetTester tester) async {
    // Set a tablet/desktop size to ensure all layout elements fit comfortably
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify Header logo and elements
    expect(find.text('JOPPE'), findsOneWidget);
    expect(find.text('DANH MỤC SẢN PHẨM'), findsOneWidget);

    // Verify Component Category Chips
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('CPU'), findsWidgets);

    // Verify Quick Actions
    expect(find.text('Build PC'), findsWidgets);
    expect(find.text('Hỗ trợ AI'), findsWidgets);

    // Verify Category Showcase
    expect(find.text('DANH MỤC TRỌNG TÂM'), findsWidgets);

    // Verify Product catalog header
    expect(find.text('KHO LINH KIỆN & THIẾT BỊ MỚI NHẤT'), findsOneWidget);
  });
}
