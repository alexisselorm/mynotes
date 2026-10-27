import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart' show immutable;

@immutable
class AuthUser {
  final String email;
  final bool isEmailVerified;

  const AuthUser({required this.email, required this.isEmailVerified});

  factory AuthUser.fromFirebase(User user) {
    return AuthUser(
      email: user.email ?? '',
      isEmailVerified: user.emailVerified,
    );
  }

  @override
  String toString() =>
      'AuthUser, email = $email, isEmailVerified = $isEmailVerified';
}
