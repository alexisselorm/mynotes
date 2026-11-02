import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/entrance.dart';
import 'package:mynotes/widgets/press_scale.dart';

const pinLength = 4;

/// A full PIN entry surface: title, four dots and a numeric keypad.
///
/// It owns only the digits typed so far; verification is left to [onCompleted]
/// so the same widget serves setup, confirmation and unlocking. [errorText]
/// is supplied by the parent, which also decides when to shake (each distinct
/// [shakeKey] value triggers one animation).
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.errorText,
    this.shakeKey = 0,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final String? errorText;
  final int shakeKey;
  final ValueChanged<String> onCompleted;
  final Widget? footer;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  final _digits = <String>[];

  @override
  void didUpdateWidget(covariant PinEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeKey != oldWidget.shakeKey) {
      _digits.clear();
      _shake.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _press(String digit) {
    if (_digits.length >= pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.add(digit));
    if (_digits.length == pinLength) {
      final pin = _digits.join();
      // Let the final dot paint before the parent decides what happens.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCompleted(pin);
      });
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Entrance(
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: AppType.style(scheme.onSurfaceVariant, 14.5, height: 1.5),
          ),
        ],
        const SizedBox(height: 30),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            // Damped oscillation: three quick swings that settle to zero.
            final dx = 10 * (1 - t) * math.sin(t * math.pi * 6);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Semantics(
            label: '${_digits.length} of $pinLength digits entered',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pinLength, (i) {
                final filled = i < _digits.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: filled ? 15 : 13,
                  height: filled ? 15 : 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasError
                        ? scheme.error
                        : filled
                        ? scheme.onSurface
                        : Colors.transparent,
                    border: Border.all(
                      color: hasError
                          ? scheme.error
                          : filled
                          ? scheme.onSurface
                          : scheme.outline,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: Center(
            child: AnimatedOpacity(
              opacity: hasError ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Text(
                widget.errorText ?? '',
                style: AppType.style(
                  scheme.error,
                  13.5,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: _Keypad(onDigit: _press, onBackspace: _backspace),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: 18),
          widget.footer!,
        ],
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row) Expanded(child: _buildKey(context, key)),
            ],
          ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    if (key.isEmpty) return const SizedBox(height: 68);
    return SizedBox(
      height: 68,
      child: Center(
        child: key == 'back'
            ? _RoundKey(
                onTap: onBackspace,
                semanticLabel: 'Delete',
                child: const Icon(Icons.backspace_outlined, size: 22),
              )
            : _RoundKey(
                onTap: () => onDigit(key),
                semanticLabel: key,
                child: Text(
                  key,
                  style: AppType.style(
                    Theme.of(context).colorScheme.onSurface,
                    26,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RoundKey extends StatelessWidget {
  const _RoundKey({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: IconTheme(
            data: IconThemeData(color: scheme.onSurface),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small caption used under the keypad on the lock screen.
class PinFootnote extends StatelessWidget {
  const PinFootnote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppType.style(
        scheme.onSurfaceVariant.withValues(alpha: 0.8),
        12,
        height: 1.5,
      ),
    );
  }
}
