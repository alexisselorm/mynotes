import 'package:flutter/foundation.dart';

/// The persisted lock configuration. The PIN itself is never kept here, only
/// its salted hash, and the whole object lives in secure storage.
@immutable
class LockSettings {
  const LockSettings({required this.pinHash, required this.biometricsEnabled});

  factory LockSettings.fromJson(Map<String, dynamic> json) {
    return LockSettings(
      pinHash: json['pinHash'] as String,
      biometricsEnabled: json['biometrics'] as bool? ?? false,
    );
  }

  final String pinHash;
  final bool biometricsEnabled;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'pinHash': pinHash,
    'biometrics': biometricsEnabled,
  };

  LockSettings copyWith({bool? biometricsEnabled}) {
    return LockSettings(
      pinHash: pinHash,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }
}
