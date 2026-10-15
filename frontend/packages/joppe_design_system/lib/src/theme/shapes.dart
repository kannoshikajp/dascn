import 'package:flutter/material.dart';

/// Google Material 3 Shape Scale values.
class JoppeShapes {
  JoppeShapes._();

  static const double none = 0.0;
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 28.0;
  static const double full = 9999.0;

  static final RoundedRectangleBorder shapeSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(small),
  );

  static final RoundedRectangleBorder shapeMedium = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(medium),
  );

  static final RoundedRectangleBorder shapeLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(large),
  );

  static final RoundedRectangleBorder shapeExtraLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(extraLarge),
  );
}
