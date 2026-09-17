import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color stepsLine = Color(0xFF2E7D32);
  static const Color hrLine = Color(0xFFC62828);
  static const Color hrSmoothedLine = Color(0xFFEF6C00);
  static const Color gridLine = Color(0x1F000000);
  static const Color tooltipBg = Color(0xE6212121);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    );
  }
}
