import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Email')),
      body: Column(
        children: [
          const Text(
            'A verification email has been sent to your email address. Please check your inbox and click on the verification link.',
          ),
          const Text('Please verify your email'),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text('Send email verification'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().reload();
            },
            child: const Text('I have verified my email'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
