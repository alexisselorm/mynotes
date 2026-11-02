import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Check your inbox',
    content:
        'A password reset link is on its way to your email address. '
        'The link expires after a short while for your safety.',
    options: const [DialogOption('Done', null)],
  );
}
