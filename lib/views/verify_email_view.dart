import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/theme/app_colors.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/app_buttons.dart';
import 'package:mynotes/widgets/entrance.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = AuthService.firebase().currentUser?.email;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Entrance(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 28,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Entrance(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check your inbox',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 32,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We sent a verification link to '
                            '${email ?? 'your email address'}. Open it to '
                            'activate your account, then come back here.',
                            style: AppType.style(
                              scheme.onSurfaceVariant,
                              15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Entrance(
                      delay: const Duration(milliseconds: 160),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkLine
                                : AppColors.lightLine,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              size: 20,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Nothing there? Give it a minute and check '
                                'your spam folder before resending.',
                                style: AppType.style(
                                  scheme.onSurfaceVariant,
                                  13.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Entrance(
                      delay: const Duration(milliseconds: 240),
                      child: PrimaryButton(
                        label: "I've verified my email",
                        icon: Icons.check_rounded,
                        onPressed: () async {
                          await AuthService.firebase().reload();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Entrance(
                      delay: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LinkButton(
                            label: 'Resend email',
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                const AuthEventSendEmailVerification(),
                              );
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('Verification email sent.'),
                                  ),
                                );
                            },
                          ),
                          LinkButton(
                            label: 'Sign out',
                            onPressed: () async {
                              await AuthService.firebase().logOut();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
