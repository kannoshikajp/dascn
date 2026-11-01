import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  test('JoppeTheme builds valid Material 3 ThemeData for light and dark modes', () {
    final light = JoppeTheme.light();
    final dark = JoppeTheme.dark();

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.colorScheme.primary, JoppeColors.lightScheme.primary);
    expect(dark.colorScheme.primary, JoppeColors.darkScheme.primary);
    expect(dark.scaffoldBackgroundColor, JoppeColors.darkScheme.surface);
  });
}
