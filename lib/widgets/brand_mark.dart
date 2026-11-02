import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's mark, drawn in code so it stays crisp at any size, can be tinted
/// in one colour, and can draw itself on.
///
/// Same geometry as the launcher icon (`tool/make_app_icon.py`): a 7°-tilted
/// note card holding an "N" with a caret bar, in 24-unit stroke space with
/// round caps.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 1.9,
    this.progress = 1,
  });

  final double size;
  final Color? color;

  /// Stroke width in the art's own 24-unit grid.
  final double strokeWidth;

  /// How much of the drawing is on screen, 0 (nothing) to 1 (complete).
  ///
  /// The card outline always traces first, then the letter, then the caret.
  /// This is a deliberate order: the frame appears, then it gets written into.
  final double progress;

  /// The artwork's overall length budgets, in 24-unit stroke space. Used by
  /// the splash to time each stroke as it finishes.
  static final double cardLength = _polylineLength(_cardPoints);
  static final double letterLength =
      _polylineLength(_letterN) + _polylineLength(_caret);
  static final double totalLength = cardLength + letterLength;

  /// Fraction of [progress] at which the card outline is complete.
  static final double cardDone = cardLength / totalLength;

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

  static double _polylineLength(List<Offset> points, {bool closed = false}) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    if (closed && points.length > 1) {
      total += (points.first - points.last).distance;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF1F5C39);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          color: resolved,
          strokeWidth: strokeWidth,
          progress: progress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final scale = size.shortestSide / 24.0;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(7 * math.pi / 180);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final cardBudget = BrandMark.cardDone;
    final cardFraction = (progress / cardBudget).clamp(0.0, 1.0);
    final letterFraction = ((progress - cardBudget) / (1 - cardBudget)).clamp(
      0.0,
      1.0,
    );

    canvas.drawPath(
      _trace(
        [
          ...BrandMark._cardPoints,
          BrandMark._cardPoints.first,
        ],
        cardFraction,
        scale,
      ),
      paint,
    );

    if (letterFraction > 0) {
      // The N and the caret are budgeted together, so the caret appears as the
      // letter's final stroke rather than after a pause.
      final nShare =
          _length(BrandMark._letterN) / BrandMark.letterLength;
      final nFraction = (letterFraction / nShare).clamp(0.0, 1.0);
      final caretFraction = ((letterFraction - nShare) / (1 - nShare)).clamp(
        0.0,
        1.0,
      );

      canvas.drawPath(_trace(BrandMark._letterN, nFraction, scale), paint);
      if (caretFraction > 0) {
        canvas.drawPath(
          _trace(BrandMark._caret, caretFraction, scale),
          paint,
        );
      }
    }

    canvas.restore();
  }

  static double _length(List<Offset> points) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    return total;
  }

  /// Builds the first [fraction] of a polyline as a scaled path.
  static Path _trace(List<Offset> points, double fraction, double scale) {
    final path = Path();
    if (fraction <= 0) return path;
    path.moveTo(points.first.dx * scale, points.first.dy * scale);
    if (fraction >= 1) {
      for (final p in points.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      return path;
    }
    final target = _length(points) * fraction;
    var travelled = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final segment = (points[i + 1] - points[i]).distance;
      if (travelled + segment >= target) {
        final t = segment == 0 ? 0.0 : (target - travelled) / segment;
        final p = Offset.lerp(points[i], points[i + 1], t)!;
        path.lineTo(p.dx * scale, p.dy * scale);
        return path;
      }
      path.lineTo(points[i + 1].dx * scale, points[i + 1].dy * scale);
      travelled += segment;
    }
    return path;
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }
}
