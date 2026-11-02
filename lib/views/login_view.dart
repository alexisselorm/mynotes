import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/app_buttons.dart';
import 'package:mynotes/widgets/app_text_field.dart';
import 'package:mynotes/widgets/auth_scaffold.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logIn(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password to continue.');
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEventLogIn(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLoggedOut && state.exception != null) {
          if (state.exception is UserNotFoundAuthException) {
            _showMessage('No account found with that email.');
          } else if (state.exception is WrongPasswordAuthException) {
            _showMessage('That password does not match.');
          } else if (state.exception is InvalidEmailAuthException) {
            _showMessage('Please enter a valid email address.');
          } else if (state.exception is GenericAuthException) {
            _showMessage('Authentication error: ${state.exception}');
          } else {
            _showMessage('Login failed: ${state.exception}');
          }
        }
      },
      child: AuthScaffold(
        overline: 'Welcome back',
        title: 'Sign in',
        subtitle: 'Pick up where your notes left off.',
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Your password',
            obscure: true,
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _logIn(context),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: LinkButton(
              label: 'Forgot your password?',
              onPressed: () {
                context.read<AuthBloc>().add(const AuthEventForgotPassword());
              },
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Sign in',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _logIn(context),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Divider(color: scheme.outline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'New here?',
                  style: AppType.style(scheme.onSurfaceVariant, 12.5),
                ),
              ),
              Expanded(child: Divider(color: scheme.outline)),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventShouldRegister());
            },
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }
}
