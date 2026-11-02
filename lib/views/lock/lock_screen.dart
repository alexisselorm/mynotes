import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/lock/biometric_service.dart';
import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';
import 'package:mynotes/views/lock/widgets/pin_entry.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/brand_mark.dart';
import 'package:mynotes/widgets/press_scale.dart';

/// Covers the app until the user proves they own the device.
///
/// Biometrics are offered first when the user has enabled them; the PIN is
/// always available as the fallback. Wrong PINs are rate limited locally with
/// an exponential backoff so the four digit space cannot be walked quickly.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.lockService,
    required this.onUnlocked,
    this.biometricService,
    this.biometricLabel,
  });

  final LockService lockService;
  final VoidCallback onUnlocked;
  final BiometricService? biometricService;

  /// E.g. "fingerprint" or "Face ID", from the device's enrolled sensors.
  final String? biometricLabel;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  static const _maxFreeAttempts = 5;

  late final BiometricService _biometrics =
      widget.biometricService ?? BiometricService();

  String? _error;
  int _shakeKey = 0;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _countdown;
  bool _promptingBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.lockService.biometricsEnabled) {
      // Let the lock screen paint before the system sheet slides up.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _authenticateWithBiometrics();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background is a natural moment to re-offer
    // biometrics, but never without the user asking twice in a row.
    if (state == AppLifecycleState.resumed &&
        widget.lockService.biometricsEnabled &&
        !_promptingBiometrics &&
        !_isLockedOut) {
      _authenticateWithBiometrics();
    }
  }

  bool get _isLockedOut {
    final until = _lockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  int get _remainingSeconds {
    final until = _lockedUntil;
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inMilliseconds;
    return diff <= 0 ? 0 : (diff / 1000).ceil();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_promptingBiometrics || _isLockedOut) return;
    setState(() {
      _promptingBiometrics = true;
      _error = null;
    });
    final ok = await _biometrics.authenticate(reason: 'Unlock My Notes');
    if (!mounted) return;
    setState(() => _promptingBiometrics = false);
    if (ok) {
      widget.onUnlocked();
    }
  }

  Future<void> _submitPin(String pin) async {
    if (_isLockedOut) return;
    final valid = await widget.lockService.verifyPin(pin);
    if (!mounted) return;
    if (valid) {
      widget.onUnlocked();
      return;
    }
    final attempts = _failedAttempts + 1;
    setState(() {
      _failedAttempts = attempts;
      _shakeKey++;
      _error = 'That PIN is not right.';
    });
    if (attempts >= _maxFreeAttempts) _startBackoff(attempts);
  }

  void _startBackoff(int attempts) {
    // 30s, 60s, 120s, ... capped at 5 minutes.
    final seconds = (30 * (1 << (attempts - _maxFreeAttempts))).clamp(30, 300);
    setState(() {
      _lockedUntil = DateTime.now().add(Duration(seconds: seconds));
      _error = null;
    });
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (!_isLockedOut) {
        timer.cancel();
        setState(() {
          _failedAttempts = 0;
          _lockedUntil = null;
        });
      }
    });
  }

  Future<void> _forgotPin() async {
    final confirmed = await showGenericDialog<bool>(
      context: context,
      title: 'Forgot your PIN?',
      content:
          'You can sign out and sign back in to remove the PIN on this '
          'device. Your notes stay safe in the cloud.',
      options: [
        const DialogOption<bool>('Cancel', false),
        const DialogOption<bool>('Sign out', true, isDestructive: true),
      ],
    );
    if (confirmed == true && mounted) {
      await widget.lockService.forgotPin();
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthEventLogOut());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final biometricsEnabled = widget.lockService.biometricsEnabled;
    final lockedOut = _isLockedOut;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: BrandMark(size: 36, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 28),
                Expanded(
                  flex: 12,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Center(
                        child: PinEntry(
                          title: 'Welcome back',
                          subtitle: lockedOut
                              ? null
                              : 'Enter your PIN to open your notes.',
                          errorText: lockedOut
                              ? 'Too many tries. Try again in '
                                    '${_remainingSeconds}s.'
                              : _error,
                          shakeKey: _shakeKey,
                          onCompleted: _submitPin,
                          footer: Column(
                            children: [
                              if (biometricsEnabled) ...[
                                _BiometricButton(
                                  label: widget.biometricLabel == null
                                      ? 'Use biometrics'
                                      : 'Use ${widget.biometricLabel}',
                                  busy: _promptingBiometrics,
                                  onTap: lockedOut
                                      ? null
                                      : _authenticateWithBiometrics,
                                ),
                                const SizedBox(height: 6),
                              ] else ...[
                                PinFootnote(
                                  text:
                                      'Biometric unlock can be turned on in '
                                      'Settings once you are in.',
                                ),
                                const SizedBox(height: 6),
                              ],
                              TextButton(
                                onPressed: _forgotPin,
                                child: const Text('Forgot PIN?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimaryContainer,
                ),
              )
            else
              Icon(
                Icons.fingerprint_rounded,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppType.style(
                scheme.onPrimaryContainer,
                14,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
