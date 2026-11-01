import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/views/overview/molecules/sales_trend_chart.dart';

void main() {
  testWidgets('SalesTrendChart renders fl_chart BarChart and toggles display mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final orders = [
      OrderSummaryModel(
        id: 'ord-1',
        orderCode: 'ORD-20261029-001',
        userId: '1',
        orderStatus: 'COMPLETED',
        paymentStatus: 'PAID',
        recipientName: 'Nguyen Van A',
        recipientPhone: '0901234567',
        finalAmount: 15000000.0,
        totalItems: 2,
        createdAt: DateTime.now(),
      ),
      OrderSummaryModel(
        id: 'ord-2',
        orderCode: 'ORD-20261028-002',
        userId: '2',
        orderStatus: 'PENDING',
        paymentStatus: 'UNPAID',
        recipientName: 'Tran Van B',
        recipientPhone: '0907654321',
        finalAmount: 25000000.0,
        totalItems: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesTrendChart(orders: orders),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify title and BarChart
    expect(find.text('Biểu đồ tăng trưởng bán hàng (7 ngày)'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Số đơn'), findsOneWidget);
    expect(find.text('Doanh thu'), findsOneWidget);

    // Toggle to Doanh thu
    await tester.tap(find.text('Doanh thu'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
  });
}
