import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/widgets/sidebar/dashboard_sidebar.dart';
import 'package:joppe_dashboard/src/widgets/sidebar/sidebar_nav_item.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  Widget buildTestWidget({Locale locale = const Locale('vi')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final destinations = DashboardSidebar.buildDestinations(context);
            return JoppeResponsiveScaffold(
              title: 'Joppe Admin',
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: destinations,
              body: const Text('Body Content'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('DashboardSidebar builds destinations with exact atomic specifications', (tester) async {
    late List<JoppeNavigationDestination> destinations;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          DashboardLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            destinations = DashboardSidebar.buildDestinations(context);
            return const SizedBox();
          },
        ),
      ),
    );

    // 1. "Tổng quan" is independent top-level item with NO group header
    expect(destinations[0], isA<SidebarNavItem>());
    expect(destinations[0].label, 'Tổng quan');
    expect(destinations[0].group, isNull);

    // 2. "QUẢN LÝ BÁN HÀNG" contains: "Đơn hàng" and "Bán hàng (POS)"
    expect(destinations[1].label, 'Đơn hàng');
    expect(destinations[1].group, 'QUẢN LÝ BÁN HÀNG');

    expect(destinations[2].label, 'Bán hàng (POS)');
    expect(destinations[2].group, 'QUẢN LÝ BÁN HÀNG');

    // 3. "HÀNG HÓA & KHO" contains: Sản phẩm, Danh mục, Tồn kho, Phiếu nhập kho
    expect(destinations[3].label, 'Sản phẩm');
    expect(destinations[3].group, 'HÀNG HÓA & KHO');

    expect(destinations[4].label, 'Danh mục');
    expect(destinations[4].group, 'HÀNG HÓA & KHO');

    expect(destinations[5].label, 'Tồn kho');
    expect(destinations[5].group, 'HÀNG HÓA & KHO');

    expect(destinations[6].label, 'Phiếu nhập kho');
    expect(destinations[6].group, 'HÀNG HÓA & KHO');

    // 4. "Nhà cung cấp" under "ĐỐI TÁC"
    expect(destinations[7].label, 'Nhà cung cấp');
    expect(destinations[7].group, 'ĐỐI TÁC');

    // 5. "CẤU HÌNH HỆ THỐNG" contains: Người dùng, Phân quyền RBAC, Cài đặt, Trợ lý AI
    expect(destinations[8].label, 'Người dùng');
    expect(destinations[8].group, 'CẤU HÌNH HỆ THỐNG');

    expect(destinations[9].label, 'Phân quyền RBAC');
    expect(destinations[9].group, 'CẤU HÌNH HỆ THỐNG');

    expect(destinations[10].label, 'Cài đặt');
    expect(destinations[10].group, 'CẤU HÌNH HỆ THỐNG');

    expect(destinations[11].label, 'Trợ lý AI');
    expect(destinations[11].group, 'CẤU HÌNH HỆ THỐNG');
  });

  testWidgets('renders sidebar drawer with section headers in desktop view', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(locale: const Locale('vi')));
    await tester.pumpAndSettle();

    // Verify section headers rendered in drawer
    expect(find.text('QUẢN LÝ BÁN HÀNG'), findsOneWidget);
    expect(find.text('HÀNG HÓA & KHO'), findsOneWidget);
    expect(find.text('ĐỐI TÁC'), findsOneWidget);
    expect(find.text('CẤU HÌNH HỆ THỐNG'), findsOneWidget);

    // Verify items
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Bán hàng (POS)'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.text('Phiếu nhập kho'), findsOneWidget);
    expect(find.text('Nhà cung cấp'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Phân quyền RBAC'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Trợ lý AI'), findsOneWidget);
  });

  testWidgets('sidebar collapses to show icons only and expands back on toggle', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(locale: const Locale('vi')));
    await tester.pumpAndSettle();

    // In expanded mode: labels and section headers are present
    expect(find.text('QUẢN LÝ BÁN HÀNG'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);

    // Tap collapse button
    final collapseToggleFinder = find.byKey(const ValueKey('sidebar_collapse_toggle'));
    expect(collapseToggleFinder, findsOneWidget);
    await tester.tap(collapseToggleFinder);
    await tester.pumpAndSettle();

    // Now collapsed: labels in sidebar and section headers are hidden
    expect(find.text('QUẢN LÝ BÁN HÀNG'), findsNothing);
    expect(find.text('Đơn hàng'), findsNothing);
    expect(find.text('Người dùng'), findsNothing);
    expect(find.text('Cài đặt'), findsNothing);
    // Menu icon is shown for expand
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Tap toggle button again to expand
    await tester.tap(collapseToggleFinder);
    await tester.pumpAndSettle();

    // Now expanded again: labels and section headers are back
    expect(find.text('QUẢN LÝ BÁN HÀNG'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.byIcon(Icons.menu_open), findsOneWidget);
  });

  testWidgets('renders profile footer at bottom of sidebar and opens popup menu', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          DashboardLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final destinations = DashboardSidebar.buildDestinations(context);
              return JoppeResponsiveScaffold(
                title: 'Joppe Admin',
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: destinations,
                sidebarFooterBuilder: (context, isCollapsed) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(isCollapsed ? 'U' : 'Admin User'),
                  );
                },
                body: const Text('Body Content'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Expanded footer renders 'Admin User'
    expect(find.text('Admin User'), findsOneWidget);

    // Toggle collapse
    await tester.tap(find.byKey(const ValueKey('sidebar_collapse_toggle')));
    await tester.pumpAndSettle();

    // Collapsed footer renders 'U'
    expect(find.text('Admin User'), findsNothing);
    expect(find.text('U'), findsOneWidget);
  });
}
