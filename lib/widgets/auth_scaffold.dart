import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_colors.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/brand_mark.dart';
import 'package:mynotes/widgets/entrance.dart';

/// Layout shared by the sign-in, sign-up and password screens: an optional
/// back button, a hand-set logo, a serif headline and a card of fields.
///
/// On wide windows the content stays in a readable column and the brand panel
/// appears beside it instead of the logo stacking on top.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.overline,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? overline;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final content = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _Card(
                  title: title,
                  subtitle: subtitle,
                  overline: overline,
                  children: children,
                ),
              );

              return Column(
                children: [
                  _TopBar(showBack: showBack),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 44),
                        child: Entrance(
                        offset: const Offset(0, 10),
                        child: wide
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _BrandPanel(),
                                  const SizedBox(width: 64),
                                  SizedBox(width: 440, child: content),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Entrance(child: _HeroLogo()),
                                  const SizedBox(height: 28),
                                  content,
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14, top: 4),
                    child: Text(
                      'My Notes  ·  your words stay yours',
                      style: AppType.style(scheme.onSurfaceVariant, 11.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/// The logo sitting on a soft rounded tile, used on narrow layouts.
class _HeroLogo extends StatelessWidget {
  const _HeroLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.lightLine,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: BrandMark(size: 38, color: AppColors.brandStrong),
      ),
    );
  }
}

/// Editorial copy shown beside the form on wide layouts. Two faint, tilted
/// sheets suggest a stack of notes behind the headline.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 380,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Two faint sheets peeking out from behind the logo, offset to the
          // side so the headline below stays completely clear.
          Positioned(
            top: 58,
            right: 6,
            child: _ghostSheet(context, angle: -6, width: 150, height: 92),
          ),
          Positioned(
            top: 70,
            right: 40,
            child: _ghostSheet(context, angle: 4, width: 150, height: 92),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 46, color: AppColors.brandStrong),
                const SizedBox(height: 34),
                Text(
                  'Think clearly.\nWrite it down.',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 44,
                    height: 1.06,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Every note is saved to your account the moment you write '
                  'it, so your thinking follows you between devices.',
                  style: AppType.style(
                    scheme.onSurfaceVariant,
                    15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ghostSheet(
    BuildContext context, {
    required double angle,
    required double width,
    required double height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : Colors.white).withValues(
              alpha: 0.72,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkLine : AppColors.lightLine,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.children,
    this.overline,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? overline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.lightLine,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (overline != null) ...[
            Text(
              overline!.toUpperCase(),
              style: AppType.overline(scheme.primary),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppType.style(scheme.onSurfaceVariant, 14.5, height: 1.5),
          ),
          const SizedBox(height: 26),
          ...children,
        ],
      ),
    );
  }
}
