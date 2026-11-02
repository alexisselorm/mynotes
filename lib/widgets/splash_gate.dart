import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/brand_mark.dart';

/// Plays a brief brand intro over the app on first frame, then dissolves into
/// the real UI.
///
/// This mirrors the native launch screen (green field, white mark) so startup
/// reads as one continuous moment instead of a native screen, a white flash and
/// then the app. The overlay does not block input once it has faded out.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  /// Total time the intro occupies the screen.
  static const total = Duration(milliseconds: 2400);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    Future<void>.delayed(SplashGate.total, _finish);
  }

  void _finish() {
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          _SplashVeil(controller: _controller),
      ],
    );
  }
}

class _SplashVeil extends StatelessWidget {
  const _SplashVeil({required this.controller});

  final AnimationController controller;

  // Phases, all relative to the 1100ms controller:
  //   0.00 - 0.55  mark scales up and settles
  //   0.25 - 0.75  wordmark and rule fade in
  //   0.80 - 1.00  veil fades out and lifts
  static const _mark = Interval(0.0, 0.55, curve: Curves.easeOutBack);
  static const _words = Interval(0.25, 0.7, curve: Curves.easeOutCubic);
  static const _exit = Interval(0.82, 1.0, curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final markT = _mark.transform(controller.value);
        final wordsT = _words.transform(controller.value);
        final exitT = _exit.transform(controller.value);

        return IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: 1 - exitT,
            child: Transform.scale(
              scale: 1 + 0.06 * exitT,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A9A63), Color(0xFF1D5737)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.82 + 0.18 * markT,
                        child: Opacity(
                          opacity: markT.clamp(0.0, 1.0),
                          child: const BrandMark(
                            size: 76,
                            color: fg,
                            strokeWidth: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Opacity(
                        opacity: wordsT,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - wordsT)),
                          child: Column(
                            children: [
                              Text(
                                'my notes',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                  color: fg.withValues(alpha: 0.96),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 34,
                                height: 1.5,
                                color: fg.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'A quiet place for your thoughts',
                                style: AppType.style(
                                  fg.withValues(alpha: 0.72),
                                  12.5,
                                  weight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
