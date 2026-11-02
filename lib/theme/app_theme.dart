import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_colors.dart';
import 'package:mynotes/theme/app_typography.dart';

/// Builds the light and dark themes. Both share the same shape language:
/// soft radii (cards are generously rounded, controls are pill-shaped) and
/// hairline borders instead of heavy shadows, so surfaces feel like paper
/// sheets stacked on a desk rather than floating Material boxes.
abstract final class AppTheme {
  static const radiusCard = 24.0;
  static const radiusField = 14.0;
  static const radiusButton = 16.0;
  static const gutter = 20.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final canvas = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final line = isDark ? AppColors.darkLine : AppColors.lightLine;
    final ink = isDark ? AppColors.darkInk : AppColors.lightInk;
    final muted = isDark ? AppColors.darkInkMuted : AppColors.lightInkMuted;
    final brand = isDark ? AppColors.darkBrand : AppColors.brand;
    final brandSoft = isDark ? AppColors.darkBrandSoft : AppColors.brandSoft;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: isDark ? AppColors.darkCanvas : Colors.white,
      primaryContainer: brandSoft,
      onPrimaryContainer: isDark ? AppColors.darkInk : AppColors.brandStrong,
      secondary: AppColors.brandSpark,
      onSecondary: isDark ? AppColors.darkCanvas : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF2E2A1C)
          : const Color(0xFFF3ECDA),
      onSecondaryContainer: isDark ? AppColors.darkInk : const Color(0xFF4A3E1B),
      tertiary: isDark ? AppColors.darkInk : AppColors.brandStrong,
      onTertiary: isDark ? AppColors.darkCanvas : Colors.white,
      error: isDark ? const Color(0xFFE99A8C) : AppColors.danger,
      onError: isDark ? AppColors.darkCanvas : Colors.white,
      errorContainer: isDark ? const Color(0xFF3A211D) : const Color(0xFFF8E3DF),
      onErrorContainer: isDark ? const Color(0xFFF3C7BF) : AppColors.danger,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: isDark ? AppColors.darkSurface : card,
      surfaceContainer: card,
      surfaceContainerHigh: card,
      surfaceContainerHighest: isDark ? AppColors.darkLine : const Color(0xFFF0EEE7),
      outline: line,
      outlineVariant: line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: canvas,
      inversePrimary: isDark ? AppColors.brand : AppColors.darkBrand,
    );

    final textTheme = AppType.textTheme(ink, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      fontFamily: AppFonts.ui,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerColor: line,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),

      iconTheme: IconThemeData(color: muted, size: 22),

      // Fields are a single soft sheet with a quiet border; focus thickens the
      // border to brand green rather than painting the whole area bright.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: AppType.style(muted, 15),
        labelStyle: AppType.style(muted, 14.5),
        floatingLabelStyle: AppType.style(brand, 13, weight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: _fieldBorder(line),
        enabledBorder: _fieldBorder(line),
        focusedBorder: _fieldBorder(brand, width: 1.6),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.6),
        prefixIconColor: muted,
        suffixIconColor: muted,
        errorStyle: AppType.style(scheme.error, 12.5),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkBrand : AppColors.brandStrong,
          foregroundColor: isDark ? AppColors.darkCanvas : Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: AppType.style(
            isDark ? AppColors.darkCanvas : Colors.white,
            16,
            weight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: AppType.style(brand, 14.5, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: line),
          textStyle: AppType.style(ink, 15.5, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: line),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: AppType.style(muted, 15, height: 1.5),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkInk : AppColors.lightInk,
        contentTextStyle: AppType.style(
          isDark ? AppColors.darkCanvas : AppColors.lightSurface,
          14,
          weight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.all(16),
        elevation: 0,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: brandSoft,
        circularTrackColor: brandSoft,
      ),

      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brand,
        selectionColor: brand.withValues(alpha: 0.22),
        selectionHandleColor: brand,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.linux: _FadeUpPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusField),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// A calm fade + short rise for pushed pages, so navigation feels like a sheet
/// sliding onto a desk rather than a hard cut.
class _FadeUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
