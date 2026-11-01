import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/settings_view.dart';

void main() {
  Widget buildSettingsWidget({
    Locale locale = const Locale('vi'),
    ThemeMode themeMode = ThemeMode.system,
    ValueChanged<Locale>? onLocaleChanged,
    ValueChanged<ThemeMode>? onThemeModeChanged,
  }) {
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
        body: SettingsView(
          currentLocale: locale,
          onLocaleChanged: onLocaleChanged ?? (_) {},
          currentThemeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders SettingsView with localized headers, language and theme cards', (tester) async {
    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Verify view header and subtitle
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Tùy chỉnh ngôn ngữ và chế độ giao diện hệ thống'), findsOneWidget);

    // Verify settings card labels
    expect(find.text('Ngôn ngữ hiển thị'), findsOneWidget);
    expect(find.text('Chọn ngôn ngữ giao diện cho toàn bộ bảng điều khiển'), findsOneWidget);
    expect(find.text('Chế độ giao diện (Màu sắc)'), findsOneWidget);
    expect(find.text('Tùy chọn giao diện sáng, tối hoặc đồng bộ theo hệ điều hành'), findsOneWidget);

    // Verify selectors are embedded
    expect(find.text('VI'), findsOneWidget);
    expect(find.text('Hệ thống'), findsOneWidget);
  });

  testWidgets('switches language from Vietnamese to English via LanguageSelector', (tester) async {
    Locale? selectedLocale;

    await tester.pumpWidget(
      buildSettingsWidget(
        locale: const Locale('vi'),
        onLocaleChanged: (loc) => selectedLocale = loc,
      ),
    );
    await tester.pumpAndSettle();

    // Open language menu
    await tester.tap(find.text('VI'));
    await tester.pumpAndSettle();

    // Tap English option
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(selectedLocale, const Locale('en'));
  });

  testWidgets('switches theme mode from system to dark and light via ThemeModeSelector', (tester) async {
    ThemeMode? selectedTheme;

    await tester.pumpWidget(
      buildSettingsWidget(
        themeMode: ThemeMode.system,
        onThemeModeChanged: (mode) => selectedTheme = mode,
      ),
    );
    await tester.pumpAndSettle();

    // Open theme menu
    await tester.tap(find.text('Hệ thống'));
    await tester.pumpAndSettle();

    // Tap Dark mode option
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(selectedTheme, ThemeMode.dark);
  });
}
