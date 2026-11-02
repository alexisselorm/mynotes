import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/theme/app_colors.dart';
import 'package:mynotes/theme/app_theme.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/notes/create_update_note_view.dart';
import 'package:mynotes/views/notes/forgot_password_view.dart';
import 'package:mynotes/views/notes/notes_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'package:mynotes/views/verify_email_view.dart';
import 'package:mynotes/widgets/splash_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  await AuthService.firebase().initialize();
  runApp(const MyNotesApp());
}

class MyNotesApp extends StatelessWidget {
  const MyNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(FirebaseAuthProvider()),
        child: const SplashGate(child: HomePage()),
      ),
      routes: {
        createUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is! AuthStateUninitialized,
      listener: (context, state) {
        // The splash stays up until there is a real screen behind it, not just
        // a spinner. Repeating this on later states is harmless.
        SplashGate.markAppReady(context);
      },
      builder: (context, state) {
        // User-triggered work (sign in, sign out, reset) shows a small
        // non-blocking status pill. The pill is dismissed as soon as the
        // state settles.
        return _AuthLoadingPill(
          isLoading: state.isLoading && state is! AuthStateUninitialized,
          label: state.loadingText ?? 'One moment…',
          child: _viewForState(state),
        );
      },
    );
  }

  Widget _viewForState(AuthState state) {
    if (state is AuthStateUninitialized) {
      return const _BootScreen();
    } else if (state is AuthStateLoggedOut) {
      return const LoginView();
    } else if (state is AuthStateNeedsVerification) {
      return const VerifyEmailView();
    } else if (state is AuthStateLoggedIn) {
      return const NotesView();
    } else if (state is AuthStateRegistering) {
      return const RegisterView();
    } else if (state is AuthStateForgotPassword) {
      return const ForgotPasswordView();
    } else {
      return const _BootScreen();
    }
  }
}

/// Shown while the first session check is in flight. It is intentionally plain
/// so it blends into the splash veil that is usually still covering it.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class _AuthLoadingPill extends StatelessWidget {
  const _AuthLoadingPill({
    required this.isLoading,
    required this.label,
    required this.child,
  });

  final bool isLoading;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: isLoading ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedSlide(
                offset: isLoading ? Offset.zero : const Offset(0, 0.25),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Center(
                  child: Material(
                    color: scheme.onSurface,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: scheme.surface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppFonts.ui,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: scheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
