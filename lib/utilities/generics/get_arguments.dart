import 'package:flutter/material.dart';

extension GetArguments on BuildContext {
  T? getArgument<T>() {
    final modalRoute = ModalRoute.of(this);
    final arguments = modalRoute?.settings.arguments;

    if (arguments is T) {
      return arguments;
    }

    return null;
  }
}
