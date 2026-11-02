import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hashes PINs for storage. Never store the PIN itself: a four digit code has
/// only 10 000 possibilities, so the salt and iteration count are the only
/// things stopping a copy of the stored value from being brute forced.
abstract final class PinHasher {
  static const _iterations = 50000;
  static const _separator = r'$';

  static final _random = Random.secure();

  static String newSalt() {
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return base64Url.encode(bytes);
  }

  /// Returns `iterations$salt$hash` (base64url parts).
  static String hash(String pin, {required String salt}) {
    final saltBytes = base64Url.decode(salt);
    var digest = sha256.convert([...saltBytes, ...utf8.encode(pin)]).bytes;
    // Each round folds the salt and the original pin back in so repeating
    // inputs cannot be cached or reduced by an attacker.
    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert([
        ...digest,
        ...saltBytes,
        ...utf8.encode(pin),
      ]).bytes;
    }
    return '$_iterations$_separator$salt$_separator${base64Url.encode(digest)}';
  }

  /// Constant-time verification of [pin] against an encoded hash.
  static bool verify(String pin, String encoded) {
    final parts = encoded.split(_separator);
    if (parts.length != 3) return false;
    final iterations = int.tryParse(parts[0]);
    if (iterations == null || iterations < 1) return false;
    final saltBytes = base64Url.decode(parts[1]);
    final expected = base64Url.decode(parts[2]);

    var digest = sha256.convert([...saltBytes, ...utf8.encode(pin)]).bytes;
    for (var i = 1; i < iterations; i++) {
      digest = sha256.convert([
        ...digest,
        ...saltBytes,
        ...utf8.encode(pin),
      ]).bytes;
    }
    return _constantTimeEquals(digest, expected);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
