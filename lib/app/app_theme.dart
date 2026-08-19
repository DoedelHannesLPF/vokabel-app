import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const pastelTurquoise = Color(0xFF7FD4D4);
  static const darkBackground = Color(0xFF121212);

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: pastelTurquoise,
      onPrimary: Color(0xFF121212),
      primaryContainer: Color(0xFF2A4545),
      onPrimaryContainer: Color(0xFFB8EBEB),
      secondary: Color(0xFF9BE0E0),
      onSecondary: Color(0xFF121212),
      secondaryContainer: Color(0xFF243838),
      onSecondaryContainer: Color(0xFFB8EBEB),
      tertiary: Color(0xFF8EC5C5),
      onTertiary: Color(0xFF121212),
      error: Color(0xFFCF6679),
      onError: Color(0xFF121212),
      errorContainer: Color(0xFF4A2530),
      onErrorContainer: Color(0xFFF5C6CE),
      surface: Color(0xFF1A1A1A),
      onSurface: Color(0xFFE8E8E8),
      onSurfaceVariant: Color(0xFF9E9E9E),
      outline: Color(0xFF444444),
      outlineVariant: Color(0xFF333333),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE8E8E8),
      onInverseSurface: Color(0xFF121212),
      inversePrimary: Color(0xFF3A8A8A),
      surfaceTint: pastelTurquoise,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF161616),
        indicatorColor: pastelTurquoise.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: pastelTurquoise, size: 24);
          }
          return const IconThemeData(color: Color(0xFF757575), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: pastelTurquoise,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Color(0xFF757575), fontSize: 12);
        }),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pastelTurquoise, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pastelTurquoise,
          foregroundColor: const Color(0xFF121212),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.primaryContainer,
      ),
    );
  }
}
