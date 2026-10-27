import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class PP {
  static const bg = Color(0xFF0B1220);
  static const card = Color(0xFF152238);
  static const accent = Color(0xFF3DDC97);
  static const warn = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5C5C);
  static const muted = Color(0xFF8B9BB4);
  static const text = Color(0xFFF4F7FB);
}

ThemeData buildParkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: PP.accent,
      secondary: PP.warn,
      surface: PP.bg,
      error: PP.danger,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: PP.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: PP.bg,
      foregroundColor: PP.text,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: PP.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? PP.bg : PP.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? PP.accent : PP.card,
      ),
    ),
  );
}
