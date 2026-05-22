import 'package:flutter/material.dart';

class AppSemantics {
  static Widget button({
    required Widget child,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: child,
        ),
      ),
    );
  }

  static Widget header({required Widget child, required String label}) {
    return Semantics(header: true, label: label, child: child);
  }

  static Widget listItem({
    required Widget child,
    String? label,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: child,
        ),
      ),
    );
  }

  static Widget image({required Widget child, required String label}) {
    return Semantics(image: true, label: label, child: child);
  }

  static Widget toggle({
    required Widget child,
    required String label,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Semantics(
      toggled: value,
      label: label,
      enabled: onChanged != null,
      child: child,
    );
  }

  static Widget slider({
    required Widget child,
    required String label,
    required double value,
  }) {
    return Semantics(
      slider: true,
      label: label,
      value: value.toStringAsFixed(0),
      child: child,
    );
  }

  static Widget liveRegion({required Widget child, String? label}) {
    return Semantics(liveRegion: true, label: label, child: child);
  }
}
