import 'package:flutter/material.dart';

/// Typefaces bundled in `assets/fonts`. Both are subset to latin, so the whole
/// pair weighs ~140 KB.
abstract final class AppFonts {
  static const ui = 'Inter';
  static const display = 'Fraunces';
}

/// Text styles. Inter carries the interface; Fraunces (a soft serif) is used
/// only for display moments, which gives the app its editorial character.
abstract final class AppType {
  static TextTheme textTheme(Color ink, Color muted) {
    return TextTheme(
      displayLarge: _display(ink, 52, 0.98),
      displayMedium: _display(ink, 40, 1.02),
      displaySmall: _display(ink, 32, 1.08),
      headlineLarge: _display(ink, 28, 1.1),
      headlineMedium: _display(ink, 24, 1.15),
      headlineSmall: _display(ink, 21, 1.2),
      titleLarge: style(ink, 19, weight: FontWeight.w600, height: 1.25),
      titleMedium: style(ink, 16, weight: FontWeight.w600, height: 1.3),
      titleSmall: style(ink, 14, weight: FontWeight.w600, height: 1.3),
      bodyLarge: style(ink, 16, height: 1.55),
      bodyMedium: style(ink, 14.5, height: 1.5),
      bodySmall: style(muted, 13, height: 1.45),
      labelLarge: style(ink, 14.5, weight: FontWeight.w600, height: 1.2),
      labelMedium: style(muted, 12.5, weight: FontWeight.w500, height: 1.2),
      labelSmall: style(muted, 11.5, weight: FontWeight.w500, height: 1.2),
    );
  }

  static TextStyle style(
    Color color,
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AppFonts.ui,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _display(Color color, double size, double height) {
    return TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: height,
      letterSpacing: -0.4,
      color: color,
    );
  }

  /// Small all-caps label used above section headings.
  static TextStyle overline(Color color) {
    return style(
      color,
      11.5,
      weight: FontWeight.w600,
      letterSpacing: 1.4,
    );
  }
}
