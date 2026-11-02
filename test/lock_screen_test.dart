import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes/services/lock/biometric_service.dart';
import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/theme/app_theme.dart';
import 'package:mynotes/views/lock/lock_screen.dart';

import 'fakes/fake_lock_storage.dart';

/// Stands in for the platform prompt without touching a channel.
class FakeBiometrics extends BiometricService {
  FakeBiometrics({this.result = false, this.calls = 0});

  final bool result;
  int calls;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String reason}) async {
    calls++;
    return result;
  }
}

Future<LockService> lockedService() async {
  final service = LockService(storage: FakeLockStorage());
  await service.setPin('1234');
  return service;
}

Future<void> pumpLock(
  WidgetTester tester,
  LockService service, {
  BiometricService? biometrics,
  VoidCallback? onUnlocked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: LockScreen(
        lockService: service,
        biometricService: biometrics,
        biometricLabel: 'fingerprint',
        onUnlocked: onUnlocked ?? () {},
      ),
    ),
  );
  await tester.pump();
}

/// Taps the keypad keys by their semantic label, which also covers labels
/// repeated elsewhere on screen (e.g. the subtitle "Four digits...").
Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    // warnIfMissed: false because the dots row carries an identical semantics
    // label; only the keypad key reaches the digit callback.
    await tester.tap(find.bySemanticsLabel(digit), warnIfMissed: false);
    await tester.pump();
  }
}

/// A completed entry schedules verification in a post-frame callback, which
/// only runs on a real end-of-frame, not a bare [WidgetTester.pump]; awaiting
/// a runAsync gap and pumping again lets it land.
Future<void> settleVerification(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('unlocks with the right PIN', (tester) async {
    final service = await lockedService();
    var unlocked = false;
    await pumpLock(tester, service, onUnlocked: () => unlocked = true);

    await enterPin(tester, '1234');
    await settleVerification(tester);

    expect(unlocked, isTrue);
    expect(find.text('That PIN is not right.'), findsNothing);
  });

  testWidgets('offers biometrics when enabled and unlocks on success', (
    tester,
  ) async {
    final service = await lockedService();
    await service.setBiometricsEnabled(true);
    final biometrics = FakeBiometrics(result: true);
    var unlocked = false;

    await pumpLock(
      tester,
      service,
      biometrics: biometrics,
      onUnlocked: () => unlocked = true,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(biometrics.calls, 1);
    expect(unlocked, isTrue);
  });

  testWidgets('falls back to the PIN when biometrics are cancelled', (
    tester,
  ) async {
    final service = await lockedService();
    await service.setBiometricsEnabled(true);
    final biometrics = FakeBiometrics(result: false);
    var unlocked = false;

    await pumpLock(
      tester,
      service,
      biometrics: biometrics,
      onUnlocked: () => unlocked = true,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(unlocked, isFalse);

    await enterPin(tester, '1234');
    await settleVerification(tester);
    expect(unlocked, isTrue);
  });

  testWidgets('shows no biometric button when the setting is off', (
    tester,
  ) async {
    final service = await lockedService();
    await pumpLock(tester, service, biometrics: FakeBiometrics());

    expect(find.text('Use fingerprint'), findsNothing);
  });
}
