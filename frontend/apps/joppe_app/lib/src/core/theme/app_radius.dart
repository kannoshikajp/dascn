import 'package:flutter/material.dart';

/// He thong bo goc cong thai hoc chuan iOS & Android theo Design DNA Warm Human Minimalism
class AppRadius {
  static const double pill = 9999.0;
  static const double card = 24.0;
  static const double cardSmall = 16.0;
  static const double button = 20.0;
  static const double input = 16.0;
  static const double sheet = 28.0;

  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius cardSmallRadius = BorderRadius.all(Radius.circular(cardSmall));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// He thong bong mo khuếch tan mem mai (Soft Ambient Diffused Shadows)
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A242424),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x12242424),
      blurRadius: 28,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x0D242424),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];
}
