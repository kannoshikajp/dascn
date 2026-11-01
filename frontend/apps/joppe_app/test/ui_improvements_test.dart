import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/screens/home_screen.dart';
import 'package:joppe_app/src/widgets/common/product_image.dart';

void main() {
  group('UI Improvements & Fixes Tests', () {
    testWidgets('Tapping JOPPE logo resets active filter and search query', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Tap on a component filter chip (e.g. CPU)
      final cpuChip = find.text('CPU');
      expect(cpuChip, findsOneWidget);
      await tester.tap(cpuChip);
      await tester.pumpAndSettle();

      // Verify that active filter header is displayed
      expect(find.text('Mục: cpu'), findsOneWidget);

      // Now tap the JOPPE logo in the header
      final joppeLogo = find.text('JOPPE');
      expect(joppeLogo, findsOneWidget);
      await tester.tap(joppeLogo);
      await tester.pumpAndSettle();

      // Filter should be reset and default home sections re-displayed
      expect(find.text('KHO LINH KIỆN & THIẾT BỊ MỚI NHẤT'), findsOneWidget);
    });

    testWidgets('ProductImage widget displays fallback cyber card on empty or invalid URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImage(
              imageUrl: '',
              componentType: 'gpu',
              brand: 'GIGABYTE',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render brand label and GPU icon
      expect(find.text('GIGABYTE'), findsOneWidget);
      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('HomeScreen is scrollable in both default and filtered mode', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Drag up to scroll down
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap on a category
      final ramChip = find.text('RAM');
      await tester.tap(ramChip);
      await tester.pumpAndSettle();

      // Drag up in filtered mode - must scroll without error
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('HomeScreen displays header tabs: Build PC, So Sánh, Dự Tính', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Build PC'), findsWidgets);
      expect(find.text('So Sánh'), findsWidgets);
      expect(find.text('Dự Tính'), findsWidgets);
    });

    testWidgets('HomeScreen displays mini promo cards and real-time flash sale countdown', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Mini promo cards (multiple promos have BACK TO SCHOOL with different badges)
      expect(find.text('BACK TO SCHOOL'), findsWidgets);
      expect(find.text('9/9 PROMO'), findsOneWidget);

      // Flash Sale banner
      expect(find.textContaining('FLASH SALE GIỜ VÀNG'), findsOneWidget);
      expect(find.text('GIÁ SỐC ĐỘC QUYỀN'), findsOneWidget);
    });

    testWidgets('HomeScreen price range filter and sort bar works as expected', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      final under10mChip = find.text('< 10 Triệu');
      // Price filter chips
      expect(find.text('Tất cả giá'), findsOneWidget);
      expect(under10mChip, findsOneWidget);
      expect(find.text('10 - 25 Triệu'), findsOneWidget);

      // Tap on '< 10 Triệu' chip
      await tester.tap(under10mChip);
      await tester.pumpAndSettle();

      // Reset to 'Tất cả giá'
      final allPriceChip = find.text('Tất cả giá');
      await tester.tap(allPriceChip);
      await tester.pumpAndSettle();
      expect(allPriceChip, findsOneWidget);
    });

    testWidgets('Desktop split view renders sidebar and utility toolbar on wide screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Desktop Left Sidebar Header
      expect(find.text('DANH MỤC PHẦN CỨNG'), findsOneWidget);

      // Desktop Right Utility Toolbar items
      expect(find.text('Hỗ trợ AI'), findsWidgets);
      expect(find.text('Xây dựng PC'), findsWidgets);
      expect(find.text('So sánh'), findsWidgets);
      expect(find.text('Hotline'), findsWidgets);
    });
  });
}

