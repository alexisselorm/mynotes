import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_colors.dart';

/// The app's mark, drawn in code so it stays crisp at any size and can be
/// tinted in one colour.
///
/// Same geometry as the launcher icon (`tool/make_app_icon.py`): a 7°-tilted
/// note card holding an "N" with a caret bar. Strokes are traced with round
/// caps at 24-unit scale, so down to very small sizes the silhouette still
/// reads as a note rather than a smudge.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 1.9,
  });

  final double size;
  final Color? color;

  /// Stroke width in the art's own 24-unit grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          color: color ?? DefaultTextStyle.of(context).style.color ??
              AppColors.brandStrong,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  static const _cardPoints = [
    Offset(-7.4, -9.0),
    Offset(7.4, -9.0),
    Offset(7.4, 9.0 - 2.4),
    Offset(-7.4, 9.0),
  ];

  static const _letterN = [
    Offset(-3.9, 4.2),
    Offset(-3.9, -4.2),
    Offset(3.4, 4.2),
    Offset(3.4, -4.2),
  ];

  static const _caret = [Offset(5.9, 5.2), Offset(5.9, -3.4)];

  @override
  void paint(Canvas canvas, Size size) {
    // The art spans a 24-unit box; scale it into [size] with a little padding
    // so round caps never clip.
    final scale = size.shortestSide / 24.0;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(7 * 3.1415926535 / 180);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()
      ..addPolygon([for (final p in _cardPoints) p * scale], true)
      ..addPolygon([for (final p in _letterN) p * scale], false)
      ..addPolygon([for (final p in _caret) p * scale], false);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
