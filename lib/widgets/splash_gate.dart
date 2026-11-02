import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/brand_mark.dart';

/// Plays the brand intro over the app on first frame, then dissolves into the
/// real UI.
///
/// The sequence is a single narrative rather than layered effects: the note
/// card traces itself, the mark is written into it, rings ripple out as it
/// settles, and while the app finishes loading the mark breathes. It only
/// ends once [child] is actually ready, so a slow cold start never leaves the
/// user staring at a finished animation.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  /// Shortest time the intro occupies the screen, so the draw-on always reads.
  static const minimum = Duration(milliseconds: 2100);

  /// Marks the intro finished building its first useful screen. The veil will
  /// not leave before this, so it never disappears into a spinner.
  static void markAppReady(BuildContext context) {
    final state = context.findAncestorStateOfType<_SplashGateState>();
    state?._markAppReady();
  }

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _breathe;
  late final AnimationController _exit;
  bool _minElapsed = false;
  bool _appReady = false;

  @override
  void initState() {
    super.initState();
    // The card traces itself for roughly the first half of this controller,
    // then the letter is written in and the caret lands last.
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    // Runs on its own clock so the hold phase can breathe independently.
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    Future<void>.delayed(SplashGate.minimum, _markMinElapsed);
  }

  void _markMinElapsed() {
    _minElapsed = true;
    _maybeExit();
  }

  void _markAppReady() {
    _appReady = true;
    _maybeExit();
  }

  void _maybeExit() {
    if (!_minElapsed || !_appReady || !mounted) return;
    _breathe.stop();
    _exit.forward();
  }

  @override
  void dispose() {
    _draw.dispose();
    _breathe.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exit,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_exit.value < 1)
              _SplashVeil(draw: _draw, breathe: _breathe, exit: _exit),
          ],
        );
      },
    );
  }
}

class _SplashVeil extends StatelessWidget {
  const _SplashVeil({
    required this.draw,
    required this.breathe,
    required this.exit,
  });

  final AnimationController draw;
  final AnimationController breathe;
  final AnimationController exit;

  static const _markSize = 104.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([draw, breathe, exit]),
        builder: (context, _) {
          final drawT = draw.value;
          final exitT = Curves.easeInCubic.transform(exit.value);

          // The wordmark appears once the frame is complete and the letter has
          // begun, so the eye moves from art to text.
          final wordsT = Curves.easeOutCubic.transform(
            ((drawT - BrandMark.cardDone) / 0.35).clamp(0.0, 1.0),
          );
          final taglineT = Curves.easeOutCubic.transform(
            ((drawT - BrandMark.cardDone - 0.18) / 0.3).clamp(0.0, 1.0),
          );

          final holding = drawT >= 1;
          final breath = holding ? breathe.value : 0.0;
          final scale = 1 + math.sin(breath * math.pi) * 0.035;

          return Opacity(
            opacity: 1 - exitT,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A9A63), Color(0xFF1D5737)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _Ripples(draw: drawT, breathe: breath, holding: holding),
                  Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandMark(
                          size: _markSize,
                          color: Colors.white,
                          strokeWidth: 1.5,
                          progress: drawT,
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: wordsT,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - wordsT)),
                            child: Semantics(
                              label: 'My Notes, loading',
                              child: ExcludeSemantics(
                                child: Column(
                                  children: [
                                    Text(
                                      'my notes',
                                      style: TextStyle(
                                        fontFamily: AppFonts.display,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                        color: Colors.white.withValues(
                                          alpha: 0.96,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Opacity(
                                      opacity: taglineT,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 1.5,
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'A quiet place for your thoughts',
                                            style: AppType.style(
                                              Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                              12.5,
                                              weight: FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rings that ripple out from the mark. Three fire in sequence as the letter
/// completes; during the hold phase a single slow ring keeps the screen alive
/// if the app takes a while to load.
class _Ripples extends StatelessWidget {
  const _Ripples({
    required this.draw,
    required this.breathe,
    required this.holding,
  });

  final double draw;
  final double breathe;
  final bool holding;

  @override
  Widget build(BuildContext context) {
    // A CustomPaint with no child sizes itself to zero inside a Stack, so the
    // rings would silently never paint. Expand to the full canvas.
    return SizedBox.expand(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _RipplePainter(
            draw: draw,
            breathe: breathe,
            holding: holding,
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.draw,
    required this.breathe,
    required this.holding,
  });

  final double draw;

  final double breathe;
  final bool holding;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = size.shortestSide;
    final markRadius = shortest * 0.13;
    final stroke = Paint()..style = PaintingStyle.stroke;

    if (holding) {
      // A single slow ring expands from the mark's edge while the app loads.
      final eased = Curves.easeInOut.transform(breathe);
      canvas.drawCircle(
        center,
        markRadius + eased * shortest * 0.3,
        stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(
            alpha: (1 - eased) * (1 - eased) * 0.22,
          ),
      );
      return;
    }

    const settleStart = 0.55;
    const span = 1 - settleStart;
    // Rings are born on the mark's own footprint and expand past it, so they
    // read as radiating from the logo rather than as distant halos.
    for (var i = 0; i < 3; i++) {
      final offset = i * 0.16;
      final raw = (draw - settleStart) / span;
      final t = (raw - offset) / (1 - offset);
      if (t <= 0 || t >= 1) continue;
      final eased = Curves.easeOutCubic.transform(t);
      canvas.drawCircle(
        center,
        markRadius + eased * shortest * 0.42,
        stroke
          ..strokeWidth = 1.5 * (1 - t) + 0.5
          ..color = Colors.white.withValues(alpha: (1 - t) * 0.34),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.draw != draw ||
        oldDelegate.breathe != breathe ||
        oldDelegate.holding != holding;
  }
}
