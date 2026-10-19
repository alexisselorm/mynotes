import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  AuthUser? get currentUser;

  Stream<AuthUser?> get authStateChanges;

  Future<void> logOut();

  Future<AuthUser> logIn({required String email, required String password});

  Future<void> sendEmailVerification();

  Future<void> reload();
}
