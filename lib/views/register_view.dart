import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateRegistering) {
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
      child: Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _register(context),
                  child: const Text('Register'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthEventLogOut());
                  },
                  child: const Text('Already Registered? Login here!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
