import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:mynotes/widgets/app_buttons.dart';
import 'package:mynotes/widgets/app_text_field.dart';
import 'package:mynotes/widgets/auth_scaffold.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter an email and a password to create an account.'),
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEventRegister(email: email, password: password),
    );
  }

  Future<void> _showAuthError(String title, String content) async {
    if (!mounted) return;
    try {
      await showErrorDialog(context, title, content);
    } catch (_) {
      // The view was popped while the dialog was open.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateRegistering && state.exception != null) {
          if (state.exception is WeakPasswordAuthException) {
            _showAuthError('Weak password', 'Please use a stronger password.');
          } else if (state.exception is EmailAlreadyInUseAuthException) {
            _showAuthError('Email already in use', 'Try logging in instead.');
          } else if (state.exception is InvalidEmailAuthException) {
            _showAuthError('Invalid email', 'Please enter a valid email.');
          } else if (state.exception is GenericAuthException) {
            _showAuthError(
              'Authentication error',
              'Something went wrong. Please try again.',
            );
          } else {
            _showAuthError('Error', state.exception.toString());
          }
        }
      },
      child: AuthScaffold(
        showBack: true,
        overline: 'Get started',
        title: 'Create account',
        subtitle: 'A private space for everything worth remembering.',
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.newUsername],
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'At least 8 characters',
            obscure: true,
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _register(context),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Create account',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _register(context),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: AppType.style(scheme.onSurfaceVariant, 13.5),
              ),
              LinkButton(
                label: 'Sign in',
                onPressed: () {
                  context.read<AuthBloc>().add(
                    const AuthEventShouldLogOut(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
