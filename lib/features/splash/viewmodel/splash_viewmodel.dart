import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../routes/routes_exports.dart';

class SplashViewModel extends ChangeNotifier {
  static const _brandDelay = Duration(milliseconds: 900);

  Future<void> resolveNextRoute() async {
    final hasSeenOnboardingFuture = storage.hasSeenOnboarding;
    await Future.delayed(_brandDelay);
    final hasSeenOnboarding = await hasSeenOnboardingFuture;
    AppNavigator.goNamed(
      hasSeenOnboarding ? RouteNames.home : RouteNames.onboarding,
    );
  }
}
