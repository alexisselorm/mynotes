import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over the platform biometric prompt so the UI never has to
/// deal with plugin-specific exceptions.
class BiometricService {
  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True when the device has a sensor and at least one biometric enrolled.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on Exception {
      return const <BiometricType>[];
    }
  }

  /// Shows the system prompt. Returns false when the user cancels or the
  /// attempt fails; errors are swallowed so callers can fall back to the PIN.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    } on LocalAuthException catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }
}
