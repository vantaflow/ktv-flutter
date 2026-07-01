import 'package:flutter/material.dart';

/// Identité visuelle de KTV. Les couleurs sont DYNAMIQUES (thème clair/sombre +
/// accent personnalisable) : ce sont des `static` réassignés par [KtvColors.apply],
/// puis l'app est reconstruite (themeVersionProvider). `rec` reste fixe (rouge).
class KtvColors {
  // Palette sombre fixe (le mode clair complet viendra dans un lot dédié).
  static const bg = Color(0xFF0E0F13);
  static const panel = Color(0xFF16181F);
  static const panel2 = Color(0xFF1E212B);
  static const line = Color(0xFF2A2D38);
  static const txt = Color(0xFFE8EAF0);
  static const muted = Color(0xFF8A8F9E);
  static const rec = Color(0xFFFF4D4D);

  // Accent DYNAMIQUE (personnalisable). Réassigné par [apply] puis rebuild.
  static Color accent = const Color(0xFFFF6A2C);
  static Color accent2 = const Color(0xFFFFB85A);

  static LinearGradient get accentGradient =>
      LinearGradient(colors: [accent, accent2], begin: Alignment.centerLeft, end: Alignment.centerRight);

  /// Palettes d'accent (accent, accent2).
  static const accents = <String, (Color, Color)>{
    'orange': (Color(0xFFFF6A2C), Color(0xFFFFB85A)),
    'blue': (Color(0xFF2C7BFF), Color(0xFF5AC8FF)),
    'green': (Color(0xFF17B26A), Color(0xFF7BE0A3)),
    'purple': (Color(0xFF8B5CF6), Color(0xFFC4A5FF)),
    'red': (Color(0xFFFF4D4D), Color(0xFFFF9A8A)),
    'pink': (Color(0xFFFF4D9D), Color(0xFFFF9AC8)),
    'teal': (Color(0xFF14B8B8), Color(0xFF6EE0E0)),
  };

  static void apply({required String accentKey}) {
    final a = accents[accentKey] ?? accents['orange']!;
    accent = a.$1;
    accent2 = a.$2;
  }
}

ThemeData buildKtvTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: KtvColors.accent,
    onPrimary: Colors.white,
    secondary: KtvColors.accent2,
    onSecondary: Colors.black,
    surface: KtvColors.panel,
    onSurface: KtvColors.txt,
    error: KtvColors.rec,
    onError: Colors.white,
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
        borderSide: BorderSide(color: KtvColors.accent, width: 1.5),
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
