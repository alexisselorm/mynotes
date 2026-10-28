import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Sign Out',
    content: 'Are you sure you want to sign out?',
    optionsBuilder: () => {'Cancel': false, 'Sign Out': true},
  ).then((value) => value ?? false);
}
