import 'package:flutter/material.dart';
import 'package:mynotes/theme/app_typography.dart';

/// A keyed option for [showGenericDialog]: the label, the value it resolves to
/// and whether it is the affirmative action (which is tinted).
class DialogOption<T> {
  const DialogOption(this.label, this.value, {this.isDestructive = false});

  final String label;
  final T? value;
  final bool isDestructive;
}

/// The app's one dialog shape: a generous rounded sheet, a serif title, calm
/// body copy and pill actions.
Future<T?> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required List<DialogOption<T>> options,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
        titlePadding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
        content: Text(
          content,
          style: AppType.style(scheme.onSurfaceVariant, 14.5, height: 1.55),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        actions: [
          for (final option in options)
            TextButton(
              onPressed: () {
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(option.value);
              },
              style: TextButton.styleFrom(
                foregroundColor: option.isDestructive
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(option.label),
            ),
        ],
      );
    },
  );
}
