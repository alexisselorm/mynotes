import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/lock/biometric_service.dart';
import 'package:mynotes/services/lock/lock_service.dart';
import 'package:mynotes/views/lock/lock_screen.dart';
import 'package:local_auth/local_auth.dart';

/// Mounts the current screen and covers it with [LockScreen] whenever the app
/// lock is enabled and currently locked.
///
/// The lock is armed on start-up and whenever the app leaves the foreground,
/// and is only released by the lock screen itself. It is deliberately
/// independent of the auth bloc: a restore from backup or a kill mid-session
/// must still find the screen covered.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  LockService? _ownedService;
  late LockService _lockService;
  late BiometricService _biometrics;

  bool _locked = true;

  /// How to name the enrolled biometric in copy, e.g. "fingerprint".
  String _biometricLabel = 'biometrics';

  /// The lock also covers the moment between sessions: once the user has
  /// been signed in, it stays up through sign-out screens until unlocked.
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final scope = context.getInheritedWidgetOfExactType<LockScope>();
    _lockService = scope?.lockService ?? (_ownedService = LockService());
    _biometrics = scope?.biometrics ?? BiometricService();
    _lockService.addListener(_onLockChanged);
    _load();
  }

  Future<void> _load() async {
    await _lockService.load();
    // Once a PIN exists the app starts locked, immediately.
    if (_lockService.isEnabled && mounted) {
      setState(() => _locked = true);
    }
    if (_lockService.biometricsEnabled) {
      final types = await _biometrics.availableTypes();
      final label = _labelFor(types);
      if (mounted) setState(() => _biometricLabel = label);
    }
  }

  static String _labelFor(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.iris)) return 'iris';
    if (types.contains(BiometricType.fingerprint)) return 'fingerprint';
    return 'biometrics';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock as soon as the app is no longer front and centre, not on `paused`:
    // Android calls paused after it has already taken the recents snapshot,
    // so the snapshot would show notes.
    final backgrounded =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;
    if (backgrounded &&
        _lockService.isEnabled &&
        !_locked &&
        _lockService.isLoaded) {
      setState(() => _locked = true);
    }
  }

  void _onLockChanged() {
    if (!mounted) return;
    setState(() {
      // Turning the lock off from settings must not leave the veil up.
      if (!_lockService.isEnabled) _locked = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockService.removeListener(_onLockChanged);
    _ownedService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final loggedIn = state is AuthStateLoggedIn;
    if (loggedIn) _wasLoggedIn = true;

    final showLock =
        _lockService.isEnabled && _locked && (loggedIn || _wasLoggedIn);

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          // Keep the whole app alive underneath so the session and the notes
          // stream survive a lock/unlock cycle, but take it out of the
          // semantics tree so its content is not announced.
          offstage: showLock,
          child: TickerMode(enabled: !showLock, child: widget.child),
        ),
        if (showLock)
          LockScreen(
            lockService: _lockService,
            biometricService: _biometrics,
            biometricLabel: _biometricLabel,
            onUnlocked: () {
              setState(() => _locked = false);
            },
          ),
      ],
    );
  }
}

/// Holds the lock services where they outlive any single screen.
///
/// It lives above [MaterialApp] in [main], so pushed routes (which are built
/// under MaterialApp's own Navigator) can still reach the lock; a scope placed
/// inside [LockGate] would be invisible to them.
class LockScope extends InheritedWidget {
  const LockScope({
    super.key,
    required this.lockService,
    required this.biometrics,
    required super.child,
  });

  final LockService lockService;
  final BiometricService biometrics;

  static LockScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LockScope>();
    assert(scope != null, 'No LockScope above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(LockScope oldWidget) =>
      lockService != oldWidget.lockService ||
      biometrics != oldWidget.biometrics;
}

/// Services for the settings page; screens that change the lock should also
/// listen to [lockServiceOf] so switches reflect saved state.
LockService lockServiceOf(BuildContext context) =>
    LockScope.of(context).lockService;
BiometricService biometricServiceOf(BuildContext context) =>
    LockScope.of(context).biometrics;
