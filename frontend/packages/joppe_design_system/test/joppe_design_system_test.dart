import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  test('JoppeTheme builds valid Material 3 ThemeData', () {
    final light = JoppeTheme.light();
    final dark = JoppeTheme.dark();

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.colorScheme.primary, JoppeColors.lightScheme.primary);
    expect(dark.colorScheme.primary, JoppeColors.darkScheme.primary);
  });
}
