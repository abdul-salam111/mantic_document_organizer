import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/theme_exports.dart';
import '../utils/utils_exports.dart';
import '../widgets/widgets_exports.dart';
import 'security_controller.dart';

/// Wraps the whole app (via `MaterialApp.router`'s `builder`, where
/// Localizations/Theme are already available) and shows a full-screen
/// biometric lock whenever [SecurityController.isBiometricLockEnabled] is
/// on and the app has just launched or returned from the background.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLocked = context.read<SecurityController>().isBiometricLockEnabled;
    if (_isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!context.read<SecurityController>().isBiometricLockEnabled) return;
    if (state == AppLifecycleState.paused) {
      setState(() => _isLocked = true);
    } else if (state == AppLifecycleState.resumed && _isLocked) {
      _attemptUnlock();
    }
  }

  Future<void> _attemptUnlock() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    final security = context.read<SecurityController>();
    final reason = AppLocalizations.of(context).biometricPromptReason;
    final success = await security.authenticate(reason);
    _isAuthenticating = false;
    if (!mounted) return;
    if (success) setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityController>(
      builder: (context, security, _) {
        final locked = security.isBiometricLockEnabled && _isLocked;
        return Stack(
          children: [
            widget.child,
            if (locked) _LockScreen(onUnlockPressed: _attemptUnlock),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlockPressed;

  const _LockScreen({required this.onUnlockPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const .all(24),
            child: Column(
              mainAxisSize: .min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: .center,
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: context.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Iconsax.finger_scan,
                    size: 36,
                    color: context.primary,
                  ),
                ),
                heightBox(20),
                Text(
                  AppLocalizations.of(context).appLocked,
                  style: context.titleMedium.copyWith(fontWeight: .bold),
                ),
                heightBox(8),
                Text(
                  AppLocalizations.of(context).unlockToContinue,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                heightBox(24),
                CustomButton(
                  text: AppLocalizations.of(context).unlock,
                  onPressed: onUnlockPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
