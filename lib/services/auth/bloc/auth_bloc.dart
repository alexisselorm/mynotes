import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
    : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user == null) {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
            loadingText: 'Please wait while we log you in',
          ),
        );
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(user: user, isLoading: false));
      }
    });

    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while we log you in',
        ),
      );
      try {
        final user = await provider.logIn(
          email: event.email,
          password: event.password,
        );
        if (!user.isEmailVerified) {
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });

    on<AuthEventLogOut>((event, emit) async {
      emit(
        const AuthStateLoading(
          isLoading: true,
          loadingText: 'Please wait while we log you out',
        ),
      );
      try {
        await provider.logOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });

    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });

    on<AuthEventRegister>((event, emit) async {
      try {
        await provider.createUser(email: event.email, password: event.password);
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });

    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(exception: null, isLoading: false));
    });

    on<AuthEventForgotPassword>((event, emit) async {
      try {
        emit(
          const AuthStateForgotPassword(
            exception: null,
            hasSentEmail: true,
            isLoading: false,
          ),
        );
        final email = event.email;
        if (email == null) {
          return;
        }
        try {
          await provider.sendPasswordReset(toEmail: email);
          emit(
            const AuthStateForgotPassword(
              exception: null,
              hasSentEmail: true,
              isLoading: false,
            ),
          );
        } on Exception catch (e) {
          emit(
            AuthStateForgotPassword(
              exception: e,
              hasSentEmail: false,
              isLoading: false,
            ),
          );
        }
      } on Exception catch (e) {
        emit(
          AuthStateForgotPassword(
            exception: e,
            hasSentEmail: false,
            isLoading: false,
          ),
        );
      }
    });
  }
}
