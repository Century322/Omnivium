import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'locale_provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('omnivium_theme_mode') ?? 'dark';
    _mode = _fromString(saved);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omnivium_theme_mode', _toString(mode));
    notifyListeners();
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.dark;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.system: return 'system';
      default: return 'dark';
    }
  }

  void setModeFromString(String modeKey) {
    setMode(_fromString(modeKey));
  }

  String get currentModeKey => _toString(_mode);

  String get currentLabel {
    switch (_mode) {
      case ThemeMode.light: return localeProvider.t('light');
      case ThemeMode.system: return localeProvider.t('system');
      default: return localeProvider.t('dark');
    }
  }

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.danger, width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent,
      selectionHandleColor: AppColors.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentBg,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.accent,
      unselectedLabelColor: Colors.white54,
      indicatorColor: AppColors.accent,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightAccent,
      surface: AppColors.lightSurface,
      error: AppColors.lightDanger,
      onSurface: Color(0xFF1C1C1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
      titleTextStyle: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w600),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.lightBackground,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Color(0xFF1C1C1E), fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: Color(0xFF1C1C1E), fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: Color(0xFF1C1C1E), fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF444444), fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Color(0xFF1C1C1E), fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: Color(0xFF444444), fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Color(0xFF444444), fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.lightAccent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.lightDanger, width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Color(0xFF1C1C1E),
      iconColor: Color(0xFF444444),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.lightAccent,
      selectionColor: AppColors.lightAccent,
      selectionHandleColor: AppColors.lightAccent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightAccent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF444444)),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceAlt,
      selectedColor: AppColors.lightAccentBg,
      labelStyle: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.lightAccent,
      unselectedLabelColor: Color(0xFF888888),
      indicatorColor: AppColors.lightAccent,
    ),
  );
}
