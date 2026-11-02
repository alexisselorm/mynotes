import 'package:flutter/material.dart';

/// The app's colour palette.
///
/// Deliberately restrained: one warm leaf green as the brand ink, and a set of
/// desaturated paper/card tones. Every surface is hand-picked rather than
/// generated from a seed, so the result reads as designed, not computed.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------
  static const brand = Color(0xFF2E7D4F);
  static const brandStrong = Color(0xFF1F5C39);
  static const brandSoft = Color(0xFFDCEEDF);
  static const brandSpark = Color(0xFFC9A227);

  // ---------------------------------------------------------------------
  // Light surfaces (card-stock, faintly warm)
  // ---------------------------------------------------------------------
  static const lightCanvas = Color(0xFFF6F5F0);
  static const lightSurface = Color(0xFFFCFBF7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightLine = Color(0xFFE4E1D8);
  static const lightInk = Color(0xFF1F231F);
  static const lightInkMuted = Color(0xFF6B7069);

  // ---------------------------------------------------------------------
  // Dark surfaces (deep forest-paper, not pure black)
  // ---------------------------------------------------------------------
  static const darkCanvas = Color(0xFF101411);
  static const darkSurface = Color(0xFF161B17);
  static const darkCard = Color(0xFF1C221D);
  static const darkLine = Color(0xFF2B332C);
  static const darkInk = Color(0xFFECEDE6);
  static const darkInkMuted = Color(0xFF9AA399);
  static const darkBrand = Color(0xFF7FC99A);
  static const darkBrandSoft = Color(0xFF22382A);

  static const danger = Color(0xFFB3402F);
}
