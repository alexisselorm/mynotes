import 'package:flutter/foundation.dart' show immutable;

typedef CloseLoadingScreen = bool Function();
typedef UpdateLoadingScreen = bool Function(String text);

@immutable
class LoadingScreenController {
  final CloseLoadingScreen _close;
  final UpdateLoadingScreen _update;

  const LoadingScreenController({required this._close, required this._update});
}
