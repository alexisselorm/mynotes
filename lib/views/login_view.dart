import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utilities/dialogs/loading_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  CloseDialog? _closeDialog;

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
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logIn(BuildContext context) async {
    final email = _emailController.text;
    final password = _passwordController.text;
    context.read<AuthBloc>().add(
      AuthEventLogIn(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLoggedOut) {
          final closeDialog = _closeDialog;
          if (!state.isLoading && closeDialog != null) {
            closeDialog();
            _closeDialog = null;
          } else if (state.isLoading && closeDialog == null) {
            _closeDialog = showLoadingDialog(
              context,
              text: 'Logging in...',
            );
          }
          if (state.exception is UserNotFoundAuthException) {
            _showMessage('User not found');
          } else if (state.exception is WrongPasswordAuthException) {
            _showMessage('Wrong credentials');
          } else if (state.exception is GenericAuthException) {
            _showMessage('Authentication error: ${state.exception}');
          } else {
            _showMessage('Login failed: ${state.exception}');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
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
                  onPressed: () => _logIn(context),
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      const AuthEventShouldRegister(),
                    );
                  },
                  child: const Text('No Account? Register here!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
