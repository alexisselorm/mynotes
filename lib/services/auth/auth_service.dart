import 'package:mynotes/services/auth/firebase_auth_provider.dart';

import 'auth_provider.dart';
import 'auth_user.dart';

class AuthService implements AuthProvider {
  final AuthProvider _authProvider;
  const AuthService(this._authProvider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  Future<void> initialize() async {
    await _authProvider.initialize();
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    return await _authProvider.createUser(email: email, password: password);
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    return await _authProvider.logIn(email: email, password: password);
  }

  @override
  Future<void> logOut() async {
    return await _authProvider.logOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    return await _authProvider.sendEmailVerification();
  }

  @override
  Future<void> reload() async {
    return await _authProvider.reload();
  }

  @override
  AuthUser? get currentUser => _authProvider.currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authProvider.authStateChanges;
}
