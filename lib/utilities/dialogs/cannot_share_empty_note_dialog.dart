import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Nothing to share yet',
    content: 'Write something in this note first, then you can share it.',
    options: const [DialogOption('OK', null)],
  );
}
