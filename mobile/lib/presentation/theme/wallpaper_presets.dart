import 'package:flutter/material.dart';

class WallpaperPresets {
  static const warm = [
    Color(0xFFFF6B35),
    Color(0xFFF7931E),
    Color(0xFFFFD700),
  ];

  static const ocean = [
    Color(0xFF0077B6),
    Color(0xFF00B4D8),
    Color(0xFF90E0EF),
  ];

  static const forest = [
    Color(0xFF2D6A4F),
    Color(0xFF40916C),
    Color(0xFF95D5B2),
  ];

  static const dark = [
    Color(0xFF0D1B2A),
    Color(0xFF1B2838),
    Color(0xFF2C3E50),
  ];

  static const pink = [
    Color(0xFFE91E63),
    Color(0xFFF06292),
    Color(0xFFF8BBD0),
  ];

  static const darkBg = Color(0xFF1A1A2E);
  static const darkBlueBg = Color(0xFF16213E);

  static List<List<Color>> get all => [warm, ocean, forest, dark, pink];

  static List<Color> get byIndex {
    final idx = DateTime.now().millisecond % all.length;
    return all[idx];
  }
}
