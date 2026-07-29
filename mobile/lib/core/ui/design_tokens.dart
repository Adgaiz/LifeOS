import 'package:flutter/animation.dart';

abstract final class LifeOsSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class LifeOsRadii {
  static const double control = 14;
  static const double card = 20;
  static const double sheet = 28;
}

abstract final class LifeOsDurations {
  static const splash = Duration(milliseconds: 900);
  static const feedback = Duration(milliseconds: 220);
}

abstract final class LifeOsCurves {
  static const Curve standard = Curves.easeOutCubic;
}
