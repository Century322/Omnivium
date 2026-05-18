import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static bool _enabled = true;
  static const _prefKey = 'omnivium_haptic_enabled';

  static bool get enabled => _enabled;

  static Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  static void lightImpact() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  static void buttonPress() => lightImpact();

  static void toggleSwitch() => selectionClick();

  static void sendMessage() => lightImpact();

  static void recordStart() => mediumImpact();

  static void recordStop() => heavyImpact();

  static void success() => mediumImpact();

  static void error() => heavyImpact();

  static void longPressStart() => mediumImpact();
}
