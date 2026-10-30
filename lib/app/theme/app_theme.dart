import 'package:flutter/material.dart';

import 'khata_colors.dart';

/// Material 3 themes built from the design tokens (Part C3).
class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF1565C0);
  static const double radiusCard = 12;
  static const double radiusButton = 14;
  static const String _latinFont = 'Inter';
  static const String _urduFont = 'NotoNastaliqUrdu';

  /// Dark primary = primary lightened by 20%.
  static Color get darkPrimary {
    final hsl = HSLColor.fromColor(_primary);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: _primary,
        onPrimary: Colors.white,
        background: const Color(0xFFF6F7F9),
        surface: Colors.white,
        text: const Color(0xFF1B1B1F),
        error: const Color(0xFFC62828),
        colors: KhataColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.black,
        background: const Color(0xFF121316),
        surface: const Color(0xFF1C1D21),
        text: const Color(0xFFECECF1),
        error: const Color(0xFFEF5350),
        colors: KhataColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color background,
    required Color surface,
    required Color text,
    required Color error,
    required KhataColors colors,
  }) {
    final isLight = brightness == Brightness.light;
    final outline = isLight ? const Color(0xFFD0D5DD) : const Color(0xFF3A3C43);

    final scheme = ColorScheme.fromSeed(seedColor: _primary, brightness: brightness).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: colors.primaryTint,
      onPrimaryContainer: isLight ? colors.primaryDark : text,
      surface: surface,
      onSurface: text,
      error: error,
      outline: outline,
      outlineVariant: outline,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.35),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 16, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      labelMedium: TextStyle(fontSize: 14, height: 1.4),
      labelSmall: TextStyle(fontSize: 12, height: 1.4),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusButton),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: _latinFont,
      fontFamilyFallback: const <String>[_urduFont],
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: text, fontFamily: _latinFont),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(color: error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: textButtonThemeData(text),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colors.primaryTint,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: text,
          );
        }),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: outline,
    );
  }

  static TextButtonThemeData textButtonThemeData(Color text) => TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
}
