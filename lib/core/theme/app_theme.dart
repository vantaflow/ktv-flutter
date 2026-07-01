import 'package:flutter/material.dart';

/// Identité visuelle « premium » de KTV : fond sombre profond, accent orange.
class KtvColors {
  static const bg = Color(0xFF0E0F13);
  static const panel = Color(0xFF16181F);
  static const panel2 = Color(0xFF1E212B);
  static const line = Color(0xFF2A2D38);
  static const txt = Color(0xFFE8EAF0);
  static const muted = Color(0xFF8A8F9E);
  static const accent = Color(0xFFFF6A2C);
  static const accent2 = Color(0xFFFFB85A);
  static const rec = Color(0xFFFF4D4D);

  static const accentGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

ThemeData buildKtvTheme() {
  const scheme = ColorScheme.dark(
    primary: KtvColors.accent,
    secondary: KtvColors.accent2,
    surface: KtvColors.panel,
    onSurface: KtvColors.txt,
    surfaceContainerHighest: KtvColors.panel2,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KtvColors.bg,
    colorScheme: scheme,
    fontFamily: 'SF Pro Display',
    dividerColor: KtvColors.line,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: KtvColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KtvColors.panel2,
      isDense: true,
      hintStyle: const TextStyle(color: KtvColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KtvColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KtvColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KtvColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KtvColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
  );
}
