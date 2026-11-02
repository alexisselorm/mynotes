import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/services/lock/lock_settings.dart';

/// In-memory stand-in for the platform keystore.
class FakeLockStorage implements LockStorage {
  LockSettings? settings;
  bool wiped = false;

  @override
  Future<LockSettings?> read() async => settings;

  @override
  Future<void> write(LockSettings value) async => settings = value;

  @override
  Future<void> clear() async => settings = null;

  @override
  Future<void> wipe() async {
    settings = null;
    wiped = true;
  }
}
