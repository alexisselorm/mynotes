import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    await Future.delayed(Duration.zero);
    _isInitialized = true;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    await Future.delayed(Duration.zero);
    return login(email: email, password: password);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    final user = AuthUser(email: email, isEmailVerified: false);
    _user = user;
    return user;
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) =>
      login(email: email, password: password);

  @override
  Future<void> logOut() async {
    if (!_isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(Duration.zero);
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    _user = AuthUser(email: user.email, isEmailVerified: true);
  }

  @override
  Future<void> reload() async {
    if (!_isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      Stream<AuthUser?>.multi((controller) {
        controller.add(_user);
      });
}
