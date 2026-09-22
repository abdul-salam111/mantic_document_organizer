import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../routes/routes_exports.dart';

class SplashViewModel extends ChangeNotifier {
  static const _brandDelay = Duration(seconds: 2);
  static const _storageTimeout = Duration(seconds: 3);

  Future<void> resolveNextRoute() async {
    // flutter_secure_storage's first-ever read on Android generates an
    // AES key via the Android Keystore, which can hang or throw on some
    // OEM builds — never let that leave the user stuck on splash forever.
    final hasSeenOnboardingFuture = storage.hasSeenOnboarding
        .timeout(_storageTimeout, onTimeout: () => false)
        .catchError((_) => false);
    await Future.delayed(_brandDelay);
    final hasSeenOnboarding = await hasSeenOnboardingFuture;
    AppNavigator.goNamed(
      hasSeenOnboarding ? RouteNames.home : RouteNames.onboarding,
    );
  }
}
