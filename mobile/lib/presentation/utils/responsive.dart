import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 768 && w < 1024;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  static double contentMaxWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return 480;
    if (w >= 768) return 420;
    return w;
  }

  static EdgeInsets safeAreaPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return EdgeInsets.zero;
  }
}
