import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
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

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await AuthService.firebase().createUser(email: email, password: password);
      await AuthService.firebase().sendEmailVerification();
    } on WeakPasswordAuthException {
      await _showAuthError('Weak password', 'Please use a stronger password.');
    } on EmailAlreadyInUseAuthException {
      await _showAuthError('Email already in use', 'Try logging in instead.');
    } on InvalidEmailAuthException {
      await _showAuthError('Invalid email', 'Please enter a valid email.');
    } on GenericAuthException {
      await _showAuthError(
        'Authentication error',
        'Something went wrong. Please try again.',
      );
    } catch (e) {
      await _showAuthError('Error', e.toString());
    }
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
    return Scaffold(
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
              TextButton(onPressed: _register, child: const Text('Register')),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login/', (route) => false);
                },
                child: const Text('Already Registered? Login here!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
