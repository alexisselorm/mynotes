import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:mynotes/utilities/dialogs/password_reset_email_sent_dialog.dart';
import 'package:mynotes/widgets/app_buttons.dart';
import 'package:mynotes/widgets/app_text_field.dart';
import 'package:mynotes/widgets/auth_scaffold.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateForgotPassword) {
          if (state.hasSentEmail) {
            _controller.clear();
            await showPasswordResetSentDialog(context);
          } else if (state.exception != null) {
            await showErrorDialog(
              context,
              'Email not sent',
              'We could not send you a password reset link. '
                  'Please make sure you are registered and try again.',
            );
          }
        }
      },
      child: AuthScaffold(
        showBack: true,
        overline: 'Password help',
        title: 'Reset password',
        subtitle: 'Enter your email and we will send you a secure reset link.',
        children: [
          AppTextField(
            controller: _controller,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _sendReset(context),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send reset link',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _sendReset(context),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remembered it?',
                style: AppType.style(scheme.onSurfaceVariant, 13.5),
              ),
              LinkButton(
                label: 'Back to sign in',
                onPressed: () {
                  _controller.clear();
                  context.read<AuthBloc>().add(const AuthEventLogOut());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendReset(BuildContext context) {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthEventForgotPassword(email: email));
  }
}
