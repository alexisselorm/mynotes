import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mynotes/services/lock/lock_settings.dart';
import 'package:mynotes/services/lock/pin_hasher.dart';

abstract interface class LockStorage {
  Future<LockSettings?> read();
  Future<void> write(LockSettings settings);
  Future<void> clear();
  Future<void> wipe();
}

/// Persists the app lock configuration in the platform keystore (Keychain on
/// Apple platforms, EncryptedSharedPreferences on Android). Only a salted PIN
/// hash is stored.
class SecureLockStorage implements LockStorage {
  SecureLockStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _settingsKey = 'app_lock_settings';

  final FlutterSecureStorage _storage;

  @override
  Future<LockSettings?> read() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null) return null;
    try {
      return LockSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // A corrupt entry should not brick the app; treat it as "no lock" so
      // the user can set a fresh PIN from settings.
      return null;
    }
  }

  @override
  Future<void> write(LockSettings settings) {
    return _storage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _settingsKey);

  /// Alternative entry for "forgot PIN": the user can prove ownership by
  /// signing in again, after which the local lock is removed.
  @override
  Future<void> wipe() async {
    await _storage.deleteAll();
  }
}

/// Reads and writes the lock while caching the current value so the lock
/// screen can show instantly instead of flashing content while it loads.
class LockService extends ChangeNotifier {
  LockService({LockStorage? storage})
    : _storage = storage ?? SecureLockStorage();

  final LockStorage _storage;

  LockSettings? _settings;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isEnabled => _settings != null;
  bool get biometricsEnabled => _settings?.biometricsEnabled ?? false;

  Future<void> load() async {
    _settings = await _storage.read();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final hash = PinHasher.hash(pin, salt: PinHasher.newSalt());
    final previous = _settings;
    _settings = LockSettings(
      pinHash: hash,
      biometricsEnabled: previous?.biometricsEnabled ?? false,
    );
    await _storage.write(_settings!);
    notifyListeners();
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final current = _settings;
    if (current == null) return;
    _settings = current.copyWith(biometricsEnabled: enabled);
    await _storage.write(_settings!);
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final current = _settings;
    if (current == null) return true;
    // Roughly 60 ms of hashing: too slow for the UI thread, but short enough
    // that not spawning an isolate per attempt is the better trade.
    return PinHasher.verify(pin, current.pinHash);
  }

  Future<void> disable() async {
    await _storage.clear();
    _settings = null;
    notifyListeners();
  }

  Future<void> forgotPin() async {
    await _storage.wipe();
    _settings = null;
    notifyListeners();
  }
}
