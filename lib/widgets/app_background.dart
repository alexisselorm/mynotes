import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_colors.dart';

/// The app's canvas: the theme background plus three very soft washes of
/// brand green placed off to the sides. They are subtle enough to read as
/// ambient light rather than decoration, and they shift with dark mode.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = isDark ? AppColors.darkBrand : AppColors.brand;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [AppColors.darkCanvas, Color(0xFF141A15)]
                  : const [AppColors.lightCanvas, Color(0xFFF1F0E9)],
            ),
          ),
        ),
        Positioned(
          top: -180,
          right: -140,
          child: _Wash(color: glow, size: 460, opacity: isDark ? 0.10 : 0.13),
        ),
        Positioned(
          bottom: -220,
          left: -160,
          child: _Wash(color: glow, size: 520, opacity: isDark ? 0.07 : 0.09),
        ),
        child,
      ],
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
