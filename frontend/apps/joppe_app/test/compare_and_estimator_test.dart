import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/models/product.dart';
import 'package:joppe_app/src/screens/compare_screen.dart';
import 'package:joppe_app/src/screens/budget_estimator_screen.dart';

void main() {
  group('CompareScreen Widget Tests', () {
    final sampleProd1 = Product(
      id: 'test-gpu-1',
      name: 'VGA ASUS ROG Strix GeForce RTX 4070 Ti Super 16GB',
      price: 26990000,
      originalPrice: 28990000,
      imageUrl: '',
      brand: 'ASUS',
      category: 'gpu',
      description: 'Card màn hình ASUS ROG Strix hiệu năng cao',
      rating: 4.9,
      reviewCount: 32,
      specs: const [
        '16GB GDDR6X',
        '256-bit',
        'Nguồn đề xuất: 750W',
      ],
      technicalSpecs: const {
        'VRAM': '16GB GDDR6X',
        'Bus': '256-bit',
        'Nguồn đề xuất': '750W',
      },
    );

    final sampleProd2 = Product(
      id: 'test-gpu-2',
      name: 'VGA MSI GeForce RTX 4070 Ti SUPER 16G VENTUS 3X OC',
      price: 24500000,
      originalPrice: 26500000,
      imageUrl: '',
      brand: 'MSI',
      category: 'gpu',
      description: 'Card màn hình MSI Ventus 3 quạt tản nhiệt',
      rating: 4.8,
      reviewCount: 19,
      specs: const [
        '16GB GDDR6X',
        '256-bit',
        'Nguồn đề xuất: 700W',
      ],
      technicalSpecs: const {
        'VRAM': '16GB GDDR6X',
        'Bus': '256-bit',
        'Nguồn đề xuất': '700W',
      },
    );

    testWidgets('CompareScreen renders products, price difference, and specs matrix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(
            initialProduct1: sampleProd1,
            initialProduct2: sampleProd2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('SO SÁNH SẢN PHẨM'), findsOneWidget);

      // Both products rendered
      expect(find.text('VGA ASUS ROG Strix GeForce RTX 4070 Ti Super 16GB'), findsWidgets);
      expect(find.text('VGA MSI GeForce RTX 4070 Ti SUPER 16G VENTUS 3X OC'), findsWidgets);

      // Brands rendered
      expect(find.text('ASUS'), findsWidgets);
      expect(find.text('MSI'), findsWidgets);

      // Price difference banner rendered
      expect(find.textContaining('CHÊNH LỆCH:'), findsOneWidget);

      // Specs matrix table header
      expect(find.text('BẢNG SO SÁNH THÔNG SỐ KỸ THUẬT'), findsOneWidget);

      // General spec labels
      expect(find.text('Thương hiệu'), findsOneWidget);
      expect(find.text('Phân loại'), findsOneWidget);
      expect(find.text('Đánh giá'), findsOneWidget);
    });

    testWidgets('CompareScreen renders empty slot placeholders when opened without params', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompareScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SO SÁNH SẢN PHẨM'), findsOneWidget);
      expect(find.byType(CompareScreen), findsOneWidget);
    });
  });

  group('BudgetEstimatorScreen Widget Tests', () {
    testWidgets('BudgetEstimatorScreen renders 3 tabs and handles tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BudgetEstimatorScreen(initialBudget: 25000000),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Tabs
      expect(find.text('DỰ TÍNH CẤU HÌNH & CHI PHÍ'), findsOneWidget);
      expect(find.text('NGÂN SÁCH'), findsWidgets);
      expect(find.text('TRẢ GÓP 0%'), findsWidgets);
      expect(find.text('TIỀN ĐIỆN'), findsWidgets);

      // Tab 1 contents: Ngân sách & Cấu hình
      expect(find.textContaining('NGÂN SÁCH DỰ KIẾN'), findsOneWidget);
      expect(find.textContaining('TỶ LỆ VÀNG'), findsOneWidget);
      expect(find.text('NẠP VÀO BUILD PC'), findsOneWidget);

      // Switch to Tab 2: TRẢ GÓP 0%
      await tester.tap(find.text('TRẢ GÓP 0%').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('GIÁ TRỊ CẤU HÌNH TRẢ GÓP'), findsOneWidget);
      expect(find.textContaining('TRẢ TRƯỚC'), findsWidgets);
      expect(find.textContaining('KỲ HẠN VAY'), findsOneWidget);
      expect(find.textContaining('GÓP MỖI THÁNG'), findsOneWidget);
      expect(find.text('6 Tháng'), findsOneWidget);

      // Switch to Tab 3: TIỀN ĐIỆN
      await tester.tap(find.text('TIỀN ĐIỆN').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('CÔNG SUẤT TIÊU THỤ'), findsOneWidget);
      expect(find.textContaining('THỜI GIAN DÙNG'), findsOneWidget);
      expect(find.textContaining('TIỀN ĐIỆN DỰ TÍNH'), findsOneWidget);
      expect(find.textContaining('MẸO TỐI ƯU ĐIỆN NĂNG'), findsOneWidget);
    });

    testWidgets('BudgetEstimatorScreen changes preset budget pills', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BudgetEstimatorScreen(initialBudget: 15000000),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 35 Triệu preset pill
      final pill35M = find.text('35 Triệu');
      expect(pill35M, findsOneWidget);
      await tester.tap(pill35M);
      await tester.pumpAndSettle();

      // Verify budget updated to 35,000,000 đ
      expect(find.textContaining('35.000.000'), findsWidgets);
    });
  });
}
