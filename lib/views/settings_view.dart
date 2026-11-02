import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mynotes/services/lock/biometric_service.dart';
import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/theme/app_typography.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';
import 'package:mynotes/views/lock/widgets/pin_entry.dart';
import 'package:mynotes/widgets/app_background.dart';
import 'package:mynotes/widgets/entrance.dart';
import 'package:mynotes/widgets/lock_gate.dart';

/// Privacy settings: enabling, changing and removing the PIN lock, and
/// choosing whether a biometric may stand in for the PIN.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  LockService? _lockRef;
  LockService get _lock => _lockRef!;
  late BiometricService _biometrics;

  bool _biometricsAvailable = false;
  String _biometricLabel = 'biometrics';
  bool _working = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lock = lockServiceOf(context);
    if (identical(lock, _lockRef)) return;
    _lockRef?.removeListener(_onLockChanged);
    _lockRef = lock..addListener(_onLockChanged);
    _biometrics = biometricServiceOf(context);
    _refreshBiometrics();
  }

  @override
  void dispose() {
    _lockRef?.removeListener(_onLockChanged);
    super.dispose();
  }

  /// The switches follow whatever was saved, including changes made on the
  /// lock screen's forgot-PIN path.
  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshBiometrics() async {
    final available = await _biometrics.isAvailable();
    String label = 'biometrics';
    if (available) {
      final types = await _biometrics.availableTypes();
      if (types.contains(BiometricType.face)) {
        label = 'Face ID';
      } else if (types.contains(BiometricType.fingerprint)) {
        label = 'fingerprint';
      } else if (types.contains(BiometricType.iris)) {
        label = 'iris';
      }
    }
    if (!mounted) return;
    setState(() {
      _biometricsAvailable = available;
      _biometricLabel = label;
    });
  }

  Future<void> _enableLock() async {
    final pin = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _PinSetupView()));
    if (pin == null || !mounted) return;
    await _lock.setPin(pin);
    if (!mounted) return;
    // Offer biometrics straight away when the device can do it: it is the
    // reason most people toggle the lock on in the first place.
    if (_biometricsAvailable && await _confirmEnableBiometrics()) {
      await _lock.setBiometricsEnabled(true);
    }
    if (mounted) _toast('App lock is on.');
  }

  Future<void> _changePin() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _VerifyPinView(lock: _lock, title: 'Enter your current PIN'),
      ),
    );
    if (unlocked != true || !mounted) return;
    final pin = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _PinSetupView()));
    if (pin == null || !mounted) return;
    await _lock.setPin(pin);
    if (mounted) _toast('PIN updated.');
  }

  Future<void> _disableLock() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _VerifyPinView(lock: _lock, title: 'Enter your PIN to turn off'),
      ),
    );
    if (unlocked != true || !mounted) return;
    await _lock.disable();
    if (mounted) _toast('App lock is off.');
  }

  Future<bool> _confirmEnableBiometrics() async {
    final ok = await showGenericDialog<bool>(
      context: context,
      title: 'Use $_biometricLabel?',
      content:
          'You can open the app with $_biometricLabel instead of typing your '
          'PIN. Your PIN will always work as a backup.',
      options: const [
        DialogOption<bool>('Not now', false),
        DialogOption<bool>('Enable', true),
      ],
    );
    return ok ?? false;
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Prove it works, and that the user intends to unlock with it, before
      // saving the preference.
      final ok = await _biometrics.authenticate(
        reason: 'Enable $_biometricLabel unlock',
      );
      if (!ok) {
        if (mounted) _toast('$_biometricLabel was not confirmed.');
        return;
      }
    }
    setState(() => _working = true);
    await _lock.setBiometricsEnabled(value);
    if (!mounted) return;
    setState(() => _working = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = _lock.isEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackground(
        // AppBackground is an expanding Stack, so it needs a bounded height
        // before the scrollable goes inside it.
        child: SizedBox.expand(
          // A Column scrolling inside a RefreshIndicator rather than a bare
          // ListView: the indicator needs a viewport below it, and this way
          // opening the page does not throw a layout assert.
          child: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: _refreshBiometrics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Entrance(
                    child: Text(
                      'Privacy',
                      style: AppType.overline(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Entrance(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'Keep your notes to yourself',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Entrance(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      'The app locks whenever you leave it and asks for your PIN '
                      'or $_biometricLabel when you come back.',
                      style: AppType.style(
                        scheme.onSurfaceVariant,
                        14,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.pin_outlined,
                        title: 'PIN lock',
                        subtitle: enabled ? 'On' : 'Off',
                        trailing: Switch.adaptive(
                          value: enabled,
                          onChanged: _working
                              ? null
                              : (value) =>
                                    value ? _enableLock() : _disableLock(),
                        ),
                        onTap: _working
                            ? null
                            : (enabled ? _disableLock : _enableLock),
                      ),
                      if (enabled) ...[
                        const Divider(height: 1),
                        _SettingsRow(
                          icon: Icons.password_rounded,
                          title: 'Change PIN',
                          subtitle: 'Set a new four-digit code',
                          onTap: _working ? null : _changePin,
                        ),
                        const Divider(height: 1),
                        _SettingsRow(
                          icon: Icons.fingerprint_rounded,
                          title: 'Unlock with $_biometricLabel',
                          subtitle: !_biometricsAvailable
                              ? 'Not set up on this device'
                              : _lock.biometricsEnabled
                              ? 'On. Your PIN still works as a backup.'
                              : 'Faster than typing your PIN',
                          trailing: Switch.adaptive(
                            value: _lock.biometricsEnabled,
                            onChanged: !_biometricsAvailable || _working
                                ? null
                                : _toggleBiometrics,
                          ),
                          onTap: !_biometricsAvailable || _working
                              ? null
                              : () =>
                                    _toggleBiometrics(!_lock.biometricsEnabled),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!_biometricsAvailable)
                    Entrance(
                      delay: const Duration(milliseconds: 160),
                      child: _HintCard(
                        icon: Icons.info_outline_rounded,
                        text:
                            'To unlock with a fingerprint or face, add one in your '
                            'device settings first.',
                      ),
                    )
                  else if (!enabled)
                    Entrance(
                      delay: const Duration(milliseconds: 160),
                      child: _HintCard(
                        icon: Icons.fingerprint_rounded,
                        text:
                            'This device supports $_biometricLabel. Turn on PIN lock '
                            'to use it.',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Entrance(
      delay: const Duration(milliseconds: 140),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The row is its own gesture detector rather than a PressScale: the
    // trailing switch handles its own taps, and here a miss on the row should
    // do nothing instead of swallowing the gesture.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppType.style(scheme.onSurfaceVariant, 12.5),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppType.style(scheme.onSurfaceVariant, 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// Choose a PIN, then type it again. Resolves to the PIN, or null if the user
/// backs out before confirmation.
class _PinSetupView extends StatefulWidget {
  const _PinSetupView();

  @override
  State<_PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends State<_PinSetupView> {
  String? _first;
  String? _error;
  int _shakeKey = 0;

  void _onCompleted(String pin) {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin == _first) {
      Navigator.of(context).pop(pin);
      return;
    }
    setState(() {
      _error = 'Those PINs did not match. Start again.';
      _shakeKey++;
      _first = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: PinEntry(
                    key: ValueKey(_first == null),
                    title: _first == null ? 'Choose a PIN' : 'Confirm your PIN',
                    subtitle: _first == null
                        ? 'Four digits. Avoid birthdays and repeated numbers.'
                        : 'Type it once more to be sure.',
                    errorText: _error,
                    shakeKey: _shakeKey,
                    onCompleted: _onCompleted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for the existing PIN before a sensitive change. Resolves to true on
/// success.
class _VerifyPinView extends StatefulWidget {
  const _VerifyPinView({required this.lock, required this.title});

  final LockService lock;
  final String title;

  @override
  State<_VerifyPinView> createState() => _VerifyPinViewState();
}

class _VerifyPinViewState extends State<_VerifyPinView> {
  String? _error;
  int _shakeKey = 0;

  Future<void> _onCompleted(String pin) async {
    final ok = await widget.lock.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = 'That PIN is not right.';
        _shakeKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: PinEntry(
                  title: widget.title,
                  errorText: _error,
                  shakeKey: _shakeKey,
                  onCompleted: _onCompleted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
