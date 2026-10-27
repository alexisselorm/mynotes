import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class FakeFirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {}

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async => AuthUser(email: email, isEmailVerified: false);

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    if (email == 'notfound@example.com') throw UserNotFoundAuthException();
    if (password != 'correct-password') throw WrongPasswordAuthException();
    return AuthUser(email: email, isEmailVerified: true);
  }

  @override
  Future<void> logOut() async => throw UserNotLoggedInAuthException();

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reload() async {}
}
