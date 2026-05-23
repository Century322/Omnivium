import 'package:flutter/material.dart';

class AccentPreset {
  final String key;
  final Color darkAccent;
  final Color lightAccent;

  const AccentPreset({
    required this.key,
    required this.darkAccent,
    required this.lightAccent,
  });

  static const teal = AccentPreset(
    key: 'teal',
    darkAccent: Color(0xFF1BCCB7),
    lightAccent: Color(0xFF0FA89E),
  );

  static const oceanBlue = AccentPreset(
    key: 'ocean_blue',
    darkAccent: Color(0xFF4A9EF5),
    lightAccent: Color(0xFF3B82F6),
  );

  static const lavender = AccentPreset(
    key: 'lavender',
    darkAccent: Color(0xFF8B6FC0),
    lightAccent: Color(0xFF7C5CBF),
  );

  static const coral = AccentPreset(
    key: 'coral',
    darkAccent: Color(0xFFE85D5D),
    lightAccent: Color(0xFFD94545),
  );

  static const amber = AccentPreset(
    key: 'amber',
    darkAccent: Color(0xFFF0963A),
    lightAccent: Color(0xFFE08520),
  );

  static const emerald = AccentPreset(
    key: 'emerald',
    darkAccent: Color(0xFF4CAF7D),
    lightAccent: Color(0xFF3D9E6E),
  );

  static const rose = AccentPreset(
    key: 'rose',
    darkAccent: Color(0xFFE07BA0),
    lightAccent: Color(0xFFD06088),
  );

  static const slate = AccentPreset(
    key: 'slate',
    darkAccent: Color(0xFF6B7FA3),
    lightAccent: Color(0xFF5A6E8F),
  );

  static const List<AccentPreset> presets = [
    teal,
    oceanBlue,
    lavender,
    coral,
    amber,
    emerald,
    rose,
    slate,
  ];

  static AccentPreset fromKey(String key) {
    return presets.firstWhere(
      (p) => p.key == key,
      orElse: () => teal,
    );
  }
}

class AppColors {
  static const Color background = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF262626);
  static const Color surfaceAlt = Color(0xFF2C2C2E);
  static const Color surfaceHover = Color(0xFF363636);
  static const Color surfaceActive = Color(0xFF3C3C3C);
  static const Color tabBg = Color(0xFF252525);
  static const Color accent = Color(0xFF1BCCB7);
  static const Color accentDark = Color(0xFF138D87);
  static const Color accentBg = Color(0xFF1A3838);
  static const Color accentLight = Color(0xFF5CC7D0);
  static const Color muted = Color(0xFF8E8E93);
  static const Color secondary = Color(0xFFB3B3B3);
  static const Color tabInactive = Color(0xFFA0A0A0);
  static const Color danger = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9500);
  static const Color success = Color(0xFF30D158);
  static const Color accentPurple = Color(0xFF5856D6);
  static const Color voiceDarkGradient = Color(0xFF112F2A);

  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEEEEE);
  static const Color lightSurfaceHover = Color(0xFFE8E8E8);
  static const Color lightSurfaceActive = Color(0xFFDDDDDD);
  static const Color lightTabBg = Color(0xFFEFEFEF);
  static const Color lightAccent = Color(0xFF0FA89E);
  static const Color lightAccentDark = Color(0xFF0B7A73);
  static const Color lightAccentBg = Color(0xFFE0F5F3);
  static const Color lightAccentLight = Color(0xFF4DB8AE);
  static const Color lightMuted = Color(0xFF8E8E93);
  static const Color lightSecondary = Color(0xFF555555);
  static const Color lightTabInactive = Color(0xFF888888);
  static const Color lightDanger = Color(0xFFE53935);
  static const Color lightWarning = Color(0xFFE68A00);
  static const Color lightSuccess = Color(0xFF28A745);

  static bool isLightMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  static Color of(BuildContext context, Color dark, Color light) {
    return isLightMode(context) ? light : dark;
  }

  static Color bg(BuildContext context) =>
      of(context, background, lightBackground);
  static Color sf(BuildContext context) => of(context, surface, lightSurface);
  static Color sfAlt(BuildContext context) =>
      of(context, surfaceAlt, lightSurfaceAlt);
  static Color sfHover(BuildContext context) =>
      of(context, surfaceHover, lightSurfaceHover);
  static Color sfActive(BuildContext context) =>
      of(context, surfaceActive, lightSurfaceActive);
  static Color tab(BuildContext context) => of(context, tabBg, lightTabBg);

  static Color acc(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color accDark(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  static Color accBg(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    if (isLightMode(context)) {
      return hsl
          .withSaturation((hsl.saturation * 0.35).clamp(0.0, 1.0))
          .withLightness(0.92)
          .toColor();
    }
    return hsl
        .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
        .withLightness(0.15)
        .toColor();
  }

  static Color accLight(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  static Color sec(BuildContext context) =>
      of(context, secondary, lightSecondary);
  static Color mut(BuildContext context) => of(context, muted, lightMuted);
  static Color tabIn(BuildContext context) =>
      of(context, tabInactive, lightTabInactive);
  static Color dng(BuildContext context) => of(context, danger, lightDanger);
  static Color warn(BuildContext context) => of(context, warning, lightWarning);
  static Color ok(BuildContext context) => of(context, success, lightSuccess);

  static Color textPrimary(BuildContext context) =>
      of(context, Colors.white, const Color(0xFF1C1C1E));
  static Color textSecondary(BuildContext context) =>
      of(context, Colors.white70, const Color(0xFF444444));
  static Color textTertiary(BuildContext context) =>
      of(context, Colors.white54, const Color(0xFF666666));
  static Color textHint(BuildContext context) =>
      of(context, Colors.white38, const Color(0xFF888888));
  static Color textDisabled(BuildContext context) =>
      of(context, Colors.white24, const Color(0xFFAAAAAA));
  static Color iconGray(BuildContext context) =>
      of(context, const Color(0xFF555555), const Color(0xFF999999));
  static Color divider(BuildContext context) =>
      of(context, const Color(0xFF2A2A2A), const Color(0xFFE0E0E0));
}
