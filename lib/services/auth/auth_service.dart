import 'auth_provider.dart';
import 'auth_user.dart';

class AuthService implements AuthProvider {
  final AuthProvider _authProvider;
  const AuthService(this._authProvider);

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) {
    // TODO: implement createUser
    return _authProvider.createUser(email: email, password: password);
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser => _authProvider.currentUser;

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    // TODO: implement logIn
    return _authProvider.logIn(email: email, password: password);
  }

  @override
  Future<void> logOut() {
    // TODO: implement logOut
    return _authProvider.logOut();
  }

  @override
  Future<void> sendEmailVerification() {
    // TODO: implement sendEmailVerification
    return _authProvider.sendEmailVerification();
  }
}
