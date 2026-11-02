import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete this note?',
    content: 'The note will be removed from your notebook permanently.',
    options: const [
      DialogOption('Cancel', false),
      DialogOption('Delete', true, isDestructive: true),
    ],
  ).then((value) => value ?? false);
}
