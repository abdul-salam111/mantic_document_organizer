import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/security/security_exports.dart';
import '../../../routes/routes_exports.dart';

class SplashViewModel extends ChangeNotifier {
  static const _brandDelay = Duration(seconds: 2);
  static const _storageTimeout = Duration(seconds: 3);

  final SecurityController _securityController;

  SplashViewModel(this._securityController);

  bool _showUnlockRetry = false;
  bool get showUnlockRetry => _showUnlockRetry;

  BiometricKind _biometricKind = BiometricKind.generic;
  BiometricKind get biometricKind => _biometricKind;

  String? _nextRouteName;

  Future<void> resolveNextRoute() async {
    // flutter_secure_storage's first-ever read on Android generates an
    // AES key via the Android Keystore, which can hang or throw on some
    // OEM builds — never let that leave the user stuck on splash forever.
    final hasSeenOnboardingFuture = storage.hasSeenOnboarding
        .timeout(_storageTimeout, onTimeout: () => false)
        .catchError((_) => false);
    await Future.delayed(_brandDelay);
    final hasSeenOnboarding = await hasSeenOnboardingFuture;
    _nextRouteName = hasSeenOnboarding
        ? RouteNames.home
        : RouteNames.onboarding;

    if (_securityController.isBiometricLockEnabled) {
      await _authenticateThenNavigate();
    } else {
      AppNavigator.goNamed(_nextRouteName!);
    }
  }

  /// Prompts biometric auth right here on the splash screen — no separate
  /// "App Locked" screen for cold start, the fingerprint/face prompt just
  /// happens as part of the normal splash flow.
  Future<void> _authenticateThenNavigate() async {
    _showUnlockRetry = false;
    notifyListeners();

    final context = AppNavigator.navigatorKey.currentContext;
    final reason = context != null
        ? AppLocalizations.of(context).biometricPromptReason
        : 'Authenticate to continue';

    _biometricKind = await _securityController.primaryBiometricKind();
    final didAuthenticate = await _securityController.authenticate(reason);

    if (didAuthenticate) {
      AppNavigator.goNamed(_nextRouteName!);
    } else {
      _showUnlockRetry = true;
      notifyListeners();
    }
  }

  void retryUnlock() => _authenticateThenNavigate();
}
