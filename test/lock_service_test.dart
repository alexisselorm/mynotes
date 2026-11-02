import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/services/lock/lock_settings.dart';
import 'package:mynotes/services/lock/pin_hasher.dart';

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

void main() {
  group('PinHasher', () {
    test('verifies the right PIN and rejects others', () {
      final hash = PinHasher.hash('1234', salt: PinHasher.newSalt());
      expect(PinHasher.verify('1234', hash), isTrue);
      expect(PinHasher.verify('1235', hash), isFalse);
      expect(PinHasher.verify('', hash), isFalse);
    });

    test('salts hashes so equal PINs differ', () {
      final a = PinHasher.hash('1234', salt: PinHasher.newSalt());
      final b = PinHasher.hash('1234', salt: PinHasher.newSalt());
      expect(a, isNot(b));
      expect(PinHasher.verify('1234', a), isTrue);
      expect(PinHasher.verify('1234', b), isTrue);
    });

    test('rejects malformed stored values', () {
      expect(PinHasher.verify('1234', 'nonsense'), isFalse);
      expect(PinHasher.verify('1234', r'0$c2FsdA$aGFzaA'), isFalse);
    });
  });

  group('LockService', () {
    late FakeLockStorage storage;
    late LockService service;

    setUp(() async {
      storage = FakeLockStorage();
      service = LockService(storage: storage);
      await service.load();
    });

    test('starts disabled', () {
      expect(service.isEnabled, isFalse);
      expect(service.biometricsEnabled, isFalse);
    });

    test('setPin enables the lock and stores only a hash', () async {
      await service.setPin('4321');
      expect(service.isEnabled, isTrue);
      expect(storage.settings!.pinHash, isNot(contains('4321')));
      expect(await service.verifyPin('4321'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
    });

    test('changing the PIN keeps the biometric preference', () async {
      await service.setPin('1111');
      await service.setBiometricsEnabled(true);
      await service.setPin('2222');
      expect(service.biometricsEnabled, isTrue);
      expect(await service.verifyPin('1111'), isFalse);
      expect(await service.verifyPin('2222'), isTrue);
    });

    test('biometric preference cannot be set without a PIN', () async {
      await service.setBiometricsEnabled(true);
      expect(service.biometricsEnabled, isFalse);
      expect(storage.settings, isNull);
    });

    test('disable removes the lock', () async {
      await service.setPin('1111');
      await service.disable();
      expect(service.isEnabled, isFalse);
      expect(storage.settings, isNull);
    });

    test('forgotPin wipes all secure storage', () async {
      await service.setPin('1111');
      await service.forgotPin();
      expect(service.isEnabled, isFalse);
      expect(storage.wiped, isTrue);
    });

    test('load restores an existing lock', () async {
      await service.setPin('9876');
      final reloaded = LockService(storage: storage);
      await reloaded.load();
      expect(reloaded.isEnabled, isTrue);
      expect(await reloaded.verifyPin('9876'), isTrue);
    });

    test('notifies listeners when the lock changes', () async {
      var notifications = 0;
      service.addListener(() => notifications++);
      await service.setPin('1111');
      await service.disable();
      expect(notifications, 2);
    });
  });
}
