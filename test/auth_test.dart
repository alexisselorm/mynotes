import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/auth_user.dart';

import 'fakes/firebase_auth/fake_firebase_auth_provider.dart';
import 'fakes/mock_auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mock auth provider', () {
    late MockAuthProvider provider;

    setUp(() => provider = MockAuthProvider());

    test('does not initialize twice', () async {
      expect(provider.currentUser, isNull);
      await provider.initialize();
      // Calling initialize again is a no-op and must not throw.
      await provider.initialize();
      expect(provider.currentUser, isNull);
    });

    test('create user should delegate to auth provider', () async {
      await provider.initialize();
      final user = await provider.createUser(
        email: 'email',
        password: 'password',
      );
      expect(user, isA<AuthUser>());
      expect(user.isEmailVerified, isFalse);
      expect(provider.currentUser, same(user));
    });

    test('create user should fail when not initialized', () async {
      expect(
        () => provider.createUser(email: 'email', password: 'password'),
        throwsA(isA<NotInitializedException>()),
      );
    });

    test('log in should set the current user', () async {
      await provider.initialize();
      final user = await provider.logIn(email: 'email', password: 'password');
      expect(provider.currentUser, same(user));
    });

    test('log in should fail when not initialized', () async {
      expect(
        () => provider.logIn(email: 'email', password: 'password'),
        throwsA(isA<NotInitializedException>()),
      );
    });

    test('log out should clear the current user', () async {
      await provider.initialize();
      await provider.logIn(email: 'email', password: 'password');
      expect(provider.currentUser, isNotNull);

      await provider.logOut();
      expect(provider.currentUser, isNull);
    });

    test('log out should fail when not logged in', () async {
      await provider.initialize();
      expect(provider.logOut, throwsA(isA<UserNotLoggedInAuthException>()));
    });

    test('email verification should mark the user as verified', () async {
      await provider.initialize();
      final user = await provider.createUser(
        email: 'email',
        password: 'password',
      );
      expect(user.isEmailVerified, isFalse);

      await provider.sendEmailVerification();
      expect(provider.currentUser?.isEmailVerified, isTrue);
    });

    test('email verification should fail when not logged in', () async {
      await provider.initialize();
      expect(
        provider.sendEmailVerification,
        throwsA(isA<UserNotLoggedInAuthException>()),
      );
    });

    test('reload should fail when not logged in', () async {
      await provider.initialize();
      expect(provider.reload, throwsA(isA<UserNotLoggedInAuthException>()));
    });

    test('auth state changes should emit the current user', () async {
      await provider.initialize();
      final user = await provider.logIn(email: 'email', password: 'password');
      expect(await provider.authStateChanges.first, same(user));
    });
  });

  group('AuthService', () {
    late AuthService service;

    setUp(() {
      service = AuthService(FakeFirebaseAuthProvider());
    });

    test('create user delegates to the provider', () async {
      final user = await service.createUser(
        email: 'email',
        password: 'password',
      );
      expect(user.isEmailVerified, isFalse);
    });

    test('log in delegates to the provider', () async {
      final user = await service.logIn(
        email: 'email',
        password: 'correct-password',
      );
      expect(user.isEmailVerified, isTrue);
    });

    test('log in should fail for unknown users', () async {
      expect(
        () => service.logIn(email: 'notfound@example.com', password: 'pw'),
        throwsA(isA<UserNotFoundAuthException>()),
      );
    });

    test('log in should fail for wrong passwords', () async {
      expect(
        () => service.logIn(email: 'email', password: 'wrong-password'),
        throwsA(isA<WrongPasswordAuthException>()),
      );
    });

    test('log out should fail when no user is signed in', () async {
      expect(service.logOut, throwsA(isA<UserNotLoggedInAuthException>()));
    });
  });
}
