import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Sign out?',
    content: 'You can sign back in any time. Your notes are kept safe.',
    options: const [
      DialogOption('Cancel', false),
      DialogOption('Sign out', true),
    ],
  ).then((value) => value ?? false);
}
